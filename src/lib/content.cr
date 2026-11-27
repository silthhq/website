# Static content of the landing page (code samples and feature catalogue).
module Site
  module Samples
    ROUTES = <<-CR
      Silth.routes do
        get "/", HomeController, :index, name: "home"

        resources "posts", PostsController do
          resources "comments", CommentsController, only: [:create]
        end

        scope "/admin", middleware: [:auth, :admin] do
          live "/dashboard", DashboardComponent
        end

        api do
          resources "posts", Api::PostsController, except: [:new, :edit]
        end
      end
      CR

    MODEL = <<-CR
      class Post < ApplicationModel
        primary_key
        column title : String
        column body : String?
        column embedding : Array(Float32)?   # pgvector
        timestamps
        soft_deletes

        belongs_to author : User
        has_many comments : Comment, dependent: :destroy

        validates title, presence: true, length: {min: 3, max: 120}

        scope published { where(published: true) }
      end

      Post.published.search([:title, :body], "fast crystal").includes(:author).paginate(1)
      Post.nearest(:embedding, query_vector).limit(5)
      CR

    CONTROLLER = <<-CR
      class PostsController < ApplicationController
        before_action :authenticate!, except: [:index, :show]

        def create
          post = current_user.posts.build.assign(params.permit(:title, :body, from: :post))
          authorize! :create, post

          if post.save
            PostPublished.new(post.id).dispatch_after_commit
            redirect route("posts.show", id: post.id), notice: t("posts.created")
          else
            render "posts/new", status: 422, post: post
          end
        end
      end
      CR

    LIVE = <<-CR
      class SearchComponent < Silth::LiveComponent
        prop query : String = "", writable: true
        template "components/search"

        def results : Array(Post)
          Post.published.search([:title], query).limit(8).to_a
        end
      end

      # src/views/components/search.html.ecr
      # <input silth-model.debounce.250ms="query" value="<%= query %>">
      # <% results.each do |post| %><p><%= post.title %></p><% end %>
      CR

    INSTALL = "silth new my_app && cd my_app && silth serve"
  end

  module Features
    record Item, name : String, en : String, fr : String

    GROUPS = {
      "http" => [
        Item.new("Routing", "Radix router, resources, scopes, constraints, named URLs", "Routeur radix, ressources, scopes, contraintes, URLs nommées"),
        Item.new("Middleware", "Global stack, web/api groups, aliases", "Pile globale, groupes web/api, alias"),
        Item.new("Templates", "Auto-escaped ECR, layouts, partials, form builder", "ECR auto-échappé, layouts, partials, formulaires"),
        Item.new("Components", "Typed props and slots, like Symfony UX", "Props typées et slots, façon Symfony UX"),
        Item.new("Assets", "No build step, fingerprinting, import maps", "Sans build, empreintes, import maps"),
        Item.new("API docs", "OpenAPI 3.1 generated from Crystal types", "OpenAPI 3.1 généré depuis les types Crystal"),
      ],
      "data" => [
        Item.new("ORM", "Models, relations, scopes, validations, dirty tracking", "Modèles, relations, scopes, validations, suivi des modifications"),
        Item.new("3 native drivers", "PostgreSQL, MySQL/MariaDB and SQLite, written in-house, with prepared statement caches and a fair pool", "PostgreSQL, MySQL/MariaDB et SQLite, écrits maison, avec cache de requêtes préparées et pool équitable"),
        Item.new("Money & dates", "Exact Decimal that keeps its scale, Date, chrono-compatible JSON times", "Decimal exact qui garde son échelle, Date, dates JSON compatibles chrono"),
        Item.new("Query builder", "Fluent, dialect-aware, CTEs, locks, upserts", "Fluide, multi-dialecte, CTE, verrous, upserts"),
        Item.new("Vectors & search", "pgvector similarity and full-text search", "Similarité pgvector et recherche plein texte"),
        Item.new("Migrations", "Versioned, transactional, schema builder", "Versionnées, transactionnelles, schema builder"),
        Item.new("Seeds & factories", "Seeders, factories and fake data", "Seeders, factories et données factices"),
      ],
      "security" => [
        Item.new("Authentication", "Sessions, remember me, API tokens, JWT (HS256/384/512), TOTP", "Sessions, remember me, tokens API, JWT (HS256/384/512), TOTP"),
        Item.new("Passwords", "Argon2id and bcrypt in-house, re-hashed on login", "Argon2id et bcrypt maison, re-hachés à la connexion"),
        Item.new("Authorization", "Policies, gates, before hooks", "Policies, gates, hooks before"),
        Item.new("CSRF & CSP", "Masked tokens, fetch metadata, CSP nonces", "Jetons masqués, fetch metadata, nonces CSP"),
        Item.new("Rate limiting", "Per user or IP, IETF headers", "Par utilisateur ou IP, en-têtes IETF"),
        Item.new("Encryption", "Encrypted cookies, signed URLs, verifiers", "Cookies chiffrés, URLs signées, vérificateurs"),
        Item.new("Billing", "Stripe subscriptions, checkout, webhooks", "Abonnements Stripe, checkout, webhooks"),
      ],
      "services" => [
        Item.new("Queues", "Sync, memory, database and Redis drivers", "Drivers sync, mémoire, base de données et Redis"),
        Item.new("Scheduler", "Cron expressions, overlap locks, time zones", "Expressions cron, verrous, fuseaux horaires"),
        Item.new("Mail", "Templates, attachments, built-in SMTP client", "Templates, pièces jointes, client SMTP intégré"),
        Item.new("Notifications", "Mail, database, broadcast, webhooks", "Mail, base de données, broadcast, webhooks"),
        Item.new("Storage", "Local and S3 with in-house SigV4", "Local et S3 avec SigV4 maison"),
        Item.new("Cache", "Memory, file, database and Redis stores", "Stores mémoire, fichier, base et Redis"),
        Item.new("Events", "Typed events, queued listeners", "Événements typés, listeners en file"),
        Item.new("i18n", "YAML catalogs, CLDR plurals, localized dates", "Catalogues YAML, pluriels CLDR, dates localisées"),
        Item.new("Workflows", "State machines with guards and diagrams", "Machines à états, gardes et diagrammes"),
        Item.new("Concurrency", "Parallel maps, timeouts, retries, deferral", "Map parallèle, timeouts, retries, différé"),
      ],
      "realtime" => [
        Item.new("Live components", "Server state, DOM morphing, no JS to write", "État serveur, morphing du DOM, zéro JS"),
        Item.new("Channels", "WebSocket topics, presence, broadcasts", "Topics WebSocket, présence, broadcasts"),
        Item.new("Server-sent events", "Streaming responses in one line", "Réponses en streaming en une ligne"),
      ],
      "ops" => [
        Item.new("Profiler", "Request timeline, toolbar, N+1 and missing translation checks", "Timeline des requêtes, toolbar, détection des N+1 et traductions manquantes"),
        Item.new("OpenTelemetry", "OTLP traces and metrics, auto-instrumented", "Traces et métriques OTLP, auto-instrumentées"),
        Item.new("Logging", "Structured, request-correlated, JSON in prod", "Structurés, corrélés, JSON en production"),
        Item.new("CLI", "Generators, scaffolds, custom commands, silth check in seconds", "Générateurs, scaffolds, commandes personnalisées, silth check en quelques secondes"),
        Item.new("Multi-core", "Supervised worker processes on one port", "Processus workers supervisés sur un même port"),
        Item.new("Testing", "In-process HTTP tests, fakes, browser tests", "Tests HTTP in-process, fakes, tests navigateur"),
        Item.new("Dev server", "Rebuild on change and live reload", "Recompilation et rechargement automatiques"),
      ],
    }
  end
end
