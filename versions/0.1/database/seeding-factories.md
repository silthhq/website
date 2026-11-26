---
title: Seeding & factories
description: Seed data, model factories and fake data.
---
# Seeding & factories

## Seeders

```crystal
# db/seeds.cr
class DatabaseSeeder < Silth::Seeder
  def run
    call UsersSeeder
    10.times { Post.create!(title: fake.title, body: fake.paragraphs(3)) }
  end
end
```

```bash
silth db:seed
silth db:seed --seeder=UsersSeeder
silth db:fresh --seed
```

## Factories

```crystal
class PostFactory < Silth::Factory(Post)
  def definition : Post
    Post.new(title: "#{fake.title} #{sequence}", body: fake.paragraph, user_id: UserFactory.create.id)
  end
end

PostFactory.build(title: "Draft")          # not saved
PostFactory.create(published: true)
PostFactory.create_list(5, user_id: user.id)
```

## Fake data

`Silth::Fake` generates names, emails, words, sentences, paragraphs, titles, slugs, URLs, cities, companies, prices, dates, booleans, UUIDs, colors and random vectors (`fake.vector(1536)`). Seed it for reproducible data: `Silth::Fake.seed(42)`.
