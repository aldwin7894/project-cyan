# frozen_string_literal: true

namespace :db do
  desc "Seed Game IDs"
  task seed_game_ids: :environment do
    GameId.delete_all
    GameId.create(name: "Genshin Impact (Asia Server)", ign: "Cyan★Nyan♪", game_id: "801533690", icon_filename: "genshin.webp")
    GameId.create(name: "Honkai: Star Rail (Asia Server)", ign: "CyanNyan", game_id: "800470038", icon_filename: "hsr.webp")
    GameId.create(name: "Tower of Fantasy (Atlantis Server)", ign: "CyanNyan", game_id: "1102113331", icon_filename: "tof.webp")
    GameId.create(name: "Blue Archive (Asia Region)", ign: "CyanNyan", game_id: "4481406", icon_filename: "bluearchive.webp")
    GameId.create(name: "BanG Dream! Girls Band Party! (EN Server)", ign: "Cyan★Nyan♪", game_id: "828925", icon_filename: "bandori_en.webp")
    GameId.create(name: "BanG Dream! Girls Band Party! (JP Server)", ign: "Cyan★Nyan♪", game_id: "105489256", icon_filename: "bandori_jp.webp")
    GameId.create(name: "Love Live! All Stars (EN Server)", ign: "Cyan★Nyan♪", game_id: "851181555", icon_filename: "lovelive_en.webp")
    GameId.create(name: "Love Live! All Stars (JP Server)", ign: "CyanNyan", game_id: "848051041", icon_filename: "lovelive_jp.webp")
    GameId.create(name: "SHOW BY ROCK!! FES A LIVE (JP Server)", ign: "CyanNyan", game_id: "UEKGJQ58", icon_filename: "shobafes.webp")
    GameId.create(name: "Uma Musume Pretty Derby (JP Server)", ign: "CyanNyan", game_id: "258149676", icon_filename: "umamusume.webp")
    GameId.create(name: "Revue Starlight Re LIVE (EN Server)", ign: "CyanNyan", game_id: "6328475113", icon_filename: "revue.webp")
  end

  desc "Seed Spotify Artist Whitelists"
  task seed_spotify_artist_whitelists: :environment do
    SpotifyArtistWhitelist.delete_all
    SpotifyArtistWhitelist.create(name: "Heavenly", spotify_id: "7j3etSXgd9ZLYIUW7KWnpd")
  end
end
