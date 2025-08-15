# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Comet.Repo.insert!(%Comet.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Comet.Repo
alias Comet.Games.Game

games = [
  %Game{
    name: "Diablo IV",
    platform: :pc,
    cover: "https://cdn2.steamgriddb.com/thumb/2217d0eff83c2f5d73845c07ad121de4.jpg",
    status: :completed
  },
  %Game{
    name: "GTA V",
    platform: :ps4,
    cover: "https://cdn2.steamgriddb.com/thumb/7a87609a1305e8c75748d20fd3a410ba.jpg",
    status: :completed
  },
  %Game{
    name: "Super Mario Odyssey",
    platform: :switch,
    cover: "https://cdn2.steamgriddb.com/thumb/505870c8848f2d550944bf64008c9472.jpg",
    status: :in_progress
  },
  %Game{
    name: "The Legend of Zelda: Breath of the Wild",
    platform: :switch,
    cover: "https://cdn2.steamgriddb.com/thumb/121b81f7d167ca2c24fdab4f044048f8.jpg",
    status: :pending
  },
  %Game{
    name: "Black Mesa",
    platform: :pc,
    cover: "https://cdn2.steamgriddb.com/thumb/89250c0d296660c427ed0d1d5059e8b7.jpg",
    status: :pending
  },
  %Game{
    name: "Metal Gear Solid 2: Sons of Liberty (2001)",
    platform: :ps2,
    cover: "https://cdn2.steamgriddb.com/thumb/483a0aa61ac760ae4f2de04a155243da.jpg",
    status: :pending
  },
  %Game{
    name: "Metal Gear Solid 3: Snake Eater (2004)",
    platform: :ps2,
    cover: "https://cdn2.steamgriddb.com/thumb/d56cee0a10eb9f1a7a969a0fd6937c13.jpg",
    status: :pending
  },
  %Game{
    name: "Dark Souls",
    platform: :pc,
    cover: "https://cdn2.steamgriddb.com/thumb/e9842c17a9e6c1d4cdfec331399f02b6.jpg",
    status: :pending
  },
  %Game{
    name: "Nier Automata",
    platform: :pc,
    cover: "https://cdn2.steamgriddb.com/thumb/6dc08e2dd57f32063fd0834694003042.jpg",
    status: :pending
  },
  %Game{
    name: "Hollow Knight",
    platform: :pc,
    cover: "https://cdn2.steamgriddb.com/thumb/d18c832e8c956b4ef8b92862e6bf470d.jpg",
    status: :pending
  },
  %Game{
    name: "Lies of P",
    platform: :pc,
    cover: "https://cdn2.steamgriddb.com/thumb/31fe38af1288e8190516ea05aec10caf.jpg",
    status: :pending
  },
  %Game{
    name: "Astro Bot",
    platform: :ps5,
    cover: "https://cdn2.steamgriddb.com/thumb/a350d0242847ce6bf914261c6e2712c1.jpg",
    status: :pending
  },
  %Game{
    name: "Final Fantasy X",
    platform: :ps2,
    cover: "https://cdn2.steamgriddb.com/thumb/95831099d5d2171aea50c24de5332f73.jpg",
    status: :pending
  },
  %Game{
    name: "Devil may Cry 3",
    platform: :ps2,
    cover: "https://cdn2.steamgriddb.com/thumb/90b260aec23ea2e4e506dc2c3a9fb0c6.jpg",
    status: :pending
  },
  %Game{
    name: "Jak X: Combat Racing",
    platform: :pc,
    cover: "https://cdn2.steamgriddb.com/thumb/8df878a8e746bb16f57beaa0615b5693.jpg",
    status: :pending
  },
  %Game{
    name: "Bloodborne",
    platform: :pc,
    cover: "https://cdn2.steamgriddb.com/thumb/021399af062379408df9c358a1a83cdb.jpg",
    status: :pending
  },
  %Game{
    name: "Donkey Kong Bananza",
    platform: :switch,
    cover: "https://cdn2.steamgriddb.com/thumb/4e8f053b3087c9ecc66e2488b1551c72.jpg",
    status: :pending
  },
  %Game{
    name: "God of War Ragnarök",
    platform: :ps4,
    cover: "https://cdn2.steamgriddb.com/thumb/fd93fd1de50e084dd7d3b0b9f6950450.jpg",
    status: :pending
  },
  %Game{
    name: "inFAMOUS Second Son",
    platform: :ps4,
    cover: "https://cdn2.steamgriddb.com/thumb/5b64cd5af426b00c26031e097fc60bfb.jpg",
    status: :pending
  },
  %Game{
    name: "Daxter",
    platform: :psp,
    cover: "https://cdn2.steamgriddb.com/thumb/47ebca2644fd2a35105cb3ab82a1d297.jpg",
    status: :pending
  }
]

for game <- games do
  Repo.insert!(game)
end
