require 'uri'
require 'net/http'
require 'json'
require 'date'
require 'liquid'
require 'yaml'

# Настройки
base_token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE3MDYwOTM1NDQsImR0YWJsZV91dWlkIjoiNTJlMjdiMjgtZmNhZS00M2ZhLTllNTktNjUxNmI0ZGIwOGM5IiwidXNlcm5hbWUiOiIiLCJwZXJtaXNzaW9uIjoicnciLCJhcHBfbmFtZSI6InN0In0.9u24w73J2PEngaed2kwrbtPWF-UWdoopEiSPTfcKV6s"  # Замените на ваш Base-Token
dtable_uuid = "52e27b28-fcae-43fa-9e59-6516b4db08c9"  # Замените на UUID вашей базы данных
table_name = 'CF_Projects'
url_data = URI("https://cloud.seatable.io/dtable-server/api/v1/dtables/#{dtable_uuid}/rows/?table_name=#{table_name}")

puts "Обработка index.md"

# прогресс-бар
10.times do |i|
    sleep 0.5 # Задержка для визуализации, можно регулировать
    print "." # Вывод символа, формирующего прогресс-бар
    STDOUT.flush # Очистка буфера вывода для обеспечения отображения каждой точки
  end
  puts

def process_content(value, keywords1, keywords2)
  if value.is_a?(String)
    value = value.gsub(/\{\{\s*keyword1\s*\}\}/) { "<strong>#{keywords1.sample}</strong>" }
    value = value.gsub(/\{\{\s*keyword2\s*\}\}/) { "<strong>#{keywords2.sample}</strong>" }
  elsif value.is_a?(Hash)
    value.each do |k, v|
      value[k] = process_content(v, keywords1, keywords2)
    end
  elsif value.is_a?(Array)
    return value.map { |v| process_content(v, keywords1, keywords2) }
  end
  value
end

def write_keywords_to_file(directory, keywords)
  File.open('result.txt', 'a') do |file|
    keywords.each do |keyword|
      file.puts "#{directory}:#{keyword}"
    end
  end
end

# Путь к вашему index.md
index_path = './index.md'

# Прочитайте содержимое index.md
content = File.read(index_path)

# Загрузите все содержимое как front matter
data = YAML.safe_load(content, permitted_classes: [Date])

# Извлеките массив ключевых слов для keyword1
keywords1 = data['main_keywords'] || []

# Загрузите конфигурационный файл
config_data = YAML.safe_load_file('_data/config.yml', permitted_classes: [Date])
lang = config_data['lang']

# Сформируйте путь к файлу ключевых слов на основе значения shop и lang
keywords2_path = "_data/#{data['shop']}_keywords_#{lang}.yml"
keywords2_data = YAML.safe_load_file(keywords2_path, permitted_classes: [Date])
keywords2 = keywords2_data['keyword']

# Обработайте все поля в данных
processed_data = process_content(data, keywords1, keywords2)

# Преобразуйте обработанные данные обратно в YAML и запишите в index.md
new_content = processed_data.to_yaml + "---\n"
File.write(index_path, new_content)

# Записываем ключевые слова в файл result.txt
current_directory = File.basename(Dir.getwd)
write_keywords_to_file(current_directory, keywords1)
puts "Ключевые слова расставлены!"
puts "index.md Сохранен!"

#Формируем файл для перелинковки
puts "Формируем файл для перелинковки _data/link.yml"
# прогресс-бар
20.times do |i|
    sleep 0.5 # Задержка для визуализации, можно регулировать
    print "." # Вывод символа, формирующего прогресс-бар
    STDOUT.flush # Очистка буфера вывода для обеспечения отображения каждой точки
  end
  puts

http_data = Net::HTTP.new(url_data.host, url_data.port)
http_data.use_ssl = true
request_data = Net::HTTP::Get.new(url_data)
request_data["Authorization"] = "Bearer #{base_token}"
request_data["Accept"] = 'application/json'

response_data = http_data.request(request_data)
if response_data.is_a?(Net::HTTPSuccess)
  data = JSON.parse(response_data.body)
  one_month_ago = DateTime.now - 30

  # Фильтрация и обработка данных
  filtered_domains = data['rows'].filter do |row|
    last_updated_str = row['Last Updated']
    next if last_updated_str.nil? || last_updated_str == "Нет данных"
    last_updated = DateTime.strptime(last_updated_str, '%Y-%m-%d %H:%M') rescue nil
    domain = row['Domain']
    project_name = row['Project Name']
    last_updated && last_updated > one_month_ago && domain && domain != "Нет данных" && project_name != "prelend-new"
  end.map { |row| "https://#{row['Domain']}" }

  # Сохранение в файл YAML в поддиректории 'data'
  File.open('_data/links.yml', 'w') do |file|
    file.write("link:\n")
    file.write(filtered_domains.map { |domain| "  - #{domain}" }.join("\n"))
  end

  puts "Данные сохранены в файл _data/links.yml"
else
  puts "Ошибка при получении данных из таблицы: #{response_data.code} #{response_data.message}"
end

system("./_jekyll-p4.sh")