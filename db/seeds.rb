# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
User.delete_all
User.create(email: "cyan@aldwin7894.win", username: "aldwin7894", password: "aldwin7894admin")

GameId.delete_all
GameId.create(name: "Genshin Impact (Asia Server)", ign: "Cyan★Nyan♪", game_id: "801533690", icon_filename: "genshin.webp")
GameId.create(name: "Tower of Fantasy (Atlantis Server)", ign: "CyanNyan", game_id: "1102113331", icon_filename: "tof.webp")
GameId.create(name: "BanG Dream! Girls Band Party! (EN Server)", ign: "Cyan★Nyan♪", game_id: "828925", icon_filename: "bandori_en.webp")
GameId.create(name: "BanG Dream! Girls Band Party! (JP Server)", ign: "Cyan★Nyan♪", game_id: "105489256", icon_filename: "bandori_jp.webp")
GameId.create(name: "Love Live! All Stars (EN Server)", ign: "Cyan★Nyan♪", game_id: "851181555", icon_filename: "lovelive_en.webp")
GameId.create(name: "Love Live! All Stars (JP Server)", ign: "CyanNyan", game_id: "848051041", icon_filename: "lovelive_jp.webp")
GameId.create(name: "SHOW BY ROCK!! FES A LIVE (JP Server)", ign: "CyanNyan", game_id: "UEKGJQ58", icon_filename: "shobafes.webp")
GameId.create(name: "Uma Musume Pretty Derby (JP Server)", ign: "CyanNyan", game_id: "258149676", icon_filename: "umamusume.webp")
GameId.create(name: "Revue Starlight Re LIVE (EN Server)", ign: "CyanNyan", game_id: "6328475113", icon_filename: "revue.webp")
