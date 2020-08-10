#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

class MyApp < Sinatra::Base
  def is_barber_exists? name
    $db.execute('SELECT * FROM barbers WHERE name=?', [name]).length > 0
  end

  # seed - наполнить
  def seed_db pbarbers
    pbarbers.each do |barber|
      if !is_barber_exists? barber
        $db.execute( 'INSERT INTO barbers (name) VALUES (?)', [barber] )
      end
    end
  end

  # Описание таблиц в БД barbershop
  # users - журнал записи посещений пользователей
  # barbers - перечень парикмахеров

  # Инициализация приложения в Sinatra
  configure do
    $db = SQLite3::Database.new 'db/barbershop.sqlite'
    $db.results_as_hash = true
    $db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS "users" (
    "id"  INTEGER PRIMARY KEY AUTOINCREMENT,
    "username"  TEXT,
    "phone"  VARCHAR,
    "datestamp"  VARCHAR,
    "email"  VARCHAR,
    "barber"  VARCHAR,
    "color"  VARCHAR
    )
    SQL

    $db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS "barbers" (
    "id"  INTEGER PRIMARY KEY AUTOINCREMENT,
    "name"  TEXT
    )
    SQL

    seed_db ['Елена', 'Татьяна', 'Вика', 'Жора']
  end

  get '/' do
    erb "Hello! <a href=\"https://github.com/bootstrap-ruby/sinatra-bootstrap\">Original</a> pattern has been modified for <a href=\"http://rubyschool.us/\">Ruby School!!!</a>"
  end

  get '/about' do
    @error = 'something wrong!'
    erb :about
  end

  get '/contacts' do
    erb :contacts
  end

  get '/visit' do
    # Получение объекта для вывода парикмахеров
    $results = $db.execute 'select * from barbers order by id'
    erb :visit
  end

  post '/visit' do
    @user_name = params[:user_name].strip
    @phone = params[:phone].strip
    @date_time = params[:date_time]
    @email = params[:email].strip
    @barber = params[:barber]
    @color = params[:colorpicker]

    # Валидация введенных данных
    hh = {
      :user_name => '* введите имя пользователя * ',
      :phone => '* укажите телефон * ',
      :date_time => '* укажите дату и время визита *',
      :barber => '* выберите мастера *'
      }

    @error = ''
    hh.each do |key, value|
      @error += hh[key] if params[key] == ''
    end

    # Если валидация пройдена, то производим запись клиента
    if @error == ''
      # Запись в файл
      f = File.open("./public/users.txt", "a")
      f.write "User name: #{@user_name}, phone: #{@phone} , email: #{@email} , visit time: #{@date_time} , master: #{@barber}\n"
      f.close

      # Запись в БД
      $db.execute( "INSERT INTO users (username, phone, datestamp, email, barber, color)
            VALUES (?, ?, ?, ?, ?, ?)", [@user_name, @phone, @date_time, @email, @barber, @color] )

      # Проверка на нового пользователя системы
      is_a_new_user?

      # Для уведомления клиента об успешной записи
      @message = "Вы успешно записаны в парикмахерскую на #{@date_time} к мастеру - #{@barber}"
    end
    erb :visit
  end

  get '/showusers' do
    $results = $db.execute 'select * from users order by id'
      erb :showusers
  end

  def is_a_new_user?
    f = File.open("./public/contacts.txt", "r+")
    arr_str = []
    while line = f.gets
      arr_str = line.split(' ')
      if arr_str[2].strip.capitalize == @user_name.capitalize
        f.close
        return false
      end
    end
    f.write "User name: #{@user_name} , phone: #{@phone} , email: #{@email}\n"
    f.close
    return true
  end
end
