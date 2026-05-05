# Idempotent dev fixture used to make a freshly-cloned worktree usable in the
# browser. Safe to run repeatedly: users and categories are looked up by their
# natural keys, and sample transactions are only inserted when the table is
# empty.

admin = User.find_or_create_by!(email: "admin@gastitos.test") do |u|
  u.name = "Admin (dev)"
  u.password = "password123"
  u.role = "admin"
  u.approved = true
end

User.find_or_create_by!(email: "viewer@gastitos.test") do |u|
  u.name = "Viewer (dev)"
  u.password = "password123"
  u.role = "viewer"
  u.approved = true
end

categories = {
  "Comida"          => "expense",
  "Transporte"      => "expense",
  "Servicios"       => "expense",
  "Salud"           => "expense",
  "Entretenimiento" => "expense",
  "Salario"         => "income",
  "Freelance"       => "income"
}.each_with_object({}) do |(name, type), memo|
  memo[name] = Category.find_or_create_by!(name: name) { |c| c.category_type = type }
end

if Transaction.count.zero?
  # [months_ago, day_of_month, category, amount, description]
  samples = [
    [ 2, 1,  "Salario",         35_000.00, "Pago de nomina" ],
    [ 2, 2,  "Comida",             420.00, "Despensa quincenal" ],
    [ 2, 4,  "Transporte",         180.00, "Uber al aeropuerto" ],
    [ 2, 5,  "Servicios",        1_240.00, "Internet" ],
    [ 2, 8,  "Comida",             310.50, "Restaurante con familia" ],
    [ 2, 12, "Entretenimiento",    260.00, "Cine" ],
    [ 2, 15, "Salud",            1_650.00, nil ],
    [ 2, 18, "Comida",             180.00, "Cafe" ],
    [ 2, 22, "Transporte",         420.00, "Gasolina" ],
    [ 2, 27, "Freelance",        4_500.00, "Proyecto web" ],

    [ 1, 1,  "Salario",         35_000.00, "Pago de nomina" ],
    [ 1, 3,  "Comida",             510.00, "Despensa" ],
    [ 1, 6,  "Servicios",        1_240.00, "Internet" ],
    [ 1, 7,  "Servicios",          820.00, "Luz" ],
    [ 1, 10, "Transporte",         220.00, nil ],
    [ 1, 13, "Comida",             340.00, "Comida con amigos" ],
    [ 1, 16, "Entretenimiento",    180.00, "Streaming" ],
    [ 1, 19, "Comida",             290.00, "Despensa rapida" ],
    [ 1, 23, "Salud",              780.00, "Farmacia" ],
    [ 1, 28, "Freelance",        2_800.00, nil ],

    [ 0, 1,  "Salario",         35_000.00, "Pago de nomina" ],
    [ 0, 2,  "Comida",             425.00, "Despensa" ],
    [ 0, 3,  "Transporte",         150.00, "Uber" ],
    [ 0, 4,  "Comida",             210.00, "Cafe matutino" ],
    [ 0, 4,  "Servicios",        1_240.00, "Internet" ]
  ]

  today = Date.current
  samples.each do |offset_months, day, cat_name, amount, description|
    base = today.beginning_of_month << offset_months
    date = base.change(day: day)
    next if date > today

    Transaction.create!(
      created_by: admin,
      category: categories.fetch(cat_name),
      amount: amount,
      date: date,
      description: description
    )
  end
end
