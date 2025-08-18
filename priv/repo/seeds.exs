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
    cover: "https://cdn2.steamgriddb.com/grid/bc0d67a22e5a847af0c9b9349d004880.webp",
    hero: "https://cdn2.steamgriddb.com/hero/365e0c4ae46e73e9e0ecdfa4e158d3a5.webp",
    status: :completed
  },
  %Game{
    name: "GTA V",
    platform: :ps4,
    cover: "https://cdn2.steamgriddb.com/grid/7a87609a1305e8c75748d20fd3a410ba.jpg",
    hero: "https://cdn2.steamgriddb.com/hero/48a0fbc23cf60d3a99d3e4e233243fa0.png",
    status: :completed
  },
  %Game{
    name: "Super Mario Odyssey",
    platform: :switch,
    cover: "https://cdn2.steamgriddb.com/grid/505870c8848f2d550944bf64008c9472.png",
    hero: "https://cdn2.steamgriddb.com/hero/c4f3d709fb9f0df27c833911dac733eb.png",
    status: :in_progress
  },
  %Game{
    name: "The Legend of Zelda: Breath of the Wild",
    platform: :switch,
    cover: "https://cdn2.steamgriddb.com/grid/121b81f7d167ca2c24fdab4f044048f8.png",
    hero: "https://cdn2.steamgriddb.com/hero/71d1c0c06e1ab5049644acb5cc69a090.png",
    status: :pending
  },
  %Game{
    name: "Black Mesa",
    platform: :pc,
    cover: "https://cdn2.steamgriddb.com/grid/810cd6adda70722fd9d2c292867b86d7.png",
    hero: "https://cdn2.steamgriddb.com/hero/275a9253dfc81efa47be4fdf1fc6a927.png",
    status: :pending
  },
  %Game{
    name: "Metal Gear Solid 2: Sons of Liberty",
    platform: :ps2,
    cover: "https://cdn2.steamgriddb.com/grid/483a0aa61ac760ae4f2de04a155243da.png",
    hero: "https://cdn2.steamgriddb.com/hero/d8cd8eedf14c62377fd9e8401ed025e1.png",
    status: :pending
  },
  %Game{
    name: "Metal Gear Solid 3: Snake Eater",
    platform: :ps2,
    cover: "https://cdn2.steamgriddb.com/grid/e081a744d57449a7ea5b84935e1adb9c.png",
    hero: "https://cdn2.steamgriddb.com/hero/d2955742de13d6802c4fecbd222abecd.jpg",
    status: :pending
  },
  %Game{
    name: "Dark Souls",
    platform: :pc,
    cover: "https://cdn2.steamgriddb.com/grid/1ef062bf592693626c0c29cbfdd253b8.png",
    hero: "https://cdn2.steamgriddb.com/hero/0e105949d99a32ca1751703e94ece601.png",
    status: :pending
  },
  # %Game{
  #   name: "Nier Automata",
  #   platform: :pc,
  #   status: :pending
  # },
  # %Game{
  #   name: "Hollow Knight",
  #   platform: :pc,
  #   status: :pending
  # },
  # %Game{
  #   name: "Lies of P",
  #   platform: :pc,
  #   status: :pending
  # },
  # %Game{
  #   name: "Astro Bot",
  #   platform: :ps5,
  #   status: :pending
  # },
  # %Game{
  #   name: "Final Fantasy X",
  #   platform: :ps2,
  #   status: :pending
  # },
  # %Game{
  #   name: "Devil may Cry 3",
  #   platform: :ps2,
  #   status: :pending
  # },
  # %Game{
  #   name: "Jak X: Combat Racing",
  #   platform: :pc,
  #   status: :pending
  # },
  # %Game{
  #   name: "Bloodborne",
  #   platform: :pc,
  #   status: :pending
  # },
  # %Game{
  #   name: "Donkey Kong Bananza",
  #   platform: :switch,
  #   status: :pending
  # },
  # %Game{
  #   name: "God of War Ragnarök",
  #   platform: :ps4,
  #   status: :pending
  # },
  # %Game{
  #   name: "inFAMOUS Second Son",
  #   platform: :ps4,
  #   status: :pending
  # },
  # %Game{
  #   name: "Daxter",
  #   platform: :psp,
  #   status: :pending
  # }
]

for game <- games do
  Repo.insert!(game)
end
