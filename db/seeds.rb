# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
AdminUser.create!(email: 'admin@prana.mx', password: 'password', password_confirmation: 'password') if Rails.env.development?

Item.create!(company: "PRANA", name: "INSCRIPCION", price: 300, commissionable_value: 0)
Item.create!(company: "PRANA", name: "PAQUETE 1", price: 2400, commissionable_value: 1000, volume: 200)
Item.create!(company: "PRANA", name: "PAQUETE 2", price: 2580, commissionable_value: 1000, volume: 200)
Item.create!(company: "PRANA", name: "PAQUETE 3", price: 2676, commissionable_value: 1000, volume: 200)
Item.create!(company: "PRANA", name: "PAQUETE 4", price: 2619, commissionable_value: 1000, volume: 200)

Item.create!(company: "OMEIN", name: "100 Puntos", description: "Una caja de Ayni", price: 1460, commissionable_value: 1107, volume: 100)
Item.create!(company: "OMEIN", name: "200 Puntos", description: "Dos cajas de Ayni", price: 2920, commissionable_value: 2214, volume: 200)
Item.create!(company: "OMEIN", name: "300 Puntos", description: "Tres cajas de Ayni", price: 4380, commissionable_value: 3321, volume: 300)
Item.create!(company: "OMEIN", name: "400 Puntos", description: "Cuatro cajas de Ayni", price: 5840, commissionable_value: 4428, volume: 400)
Item.create!(company: "OMEIN", name: "1600 Puntos", description: "16 cajas de Ayni", price: 23360, commissionable_value: 17712, volume: 1600)
