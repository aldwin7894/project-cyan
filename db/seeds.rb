# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
User.delete_all
ActiveRecord::Base.connection.execute('ALTER SEQUENCE users_id_seq RESTART WITH 1;')
User.create(email: 'aldwinph.basilio@gmail.com', username: 'aldwin7894', password: 'aldwin7894admin')
