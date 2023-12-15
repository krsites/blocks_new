require 'liquid'
require 'yaml'

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
data = YAML.load(content)

# Извлеките массив ключевых слов для keyword1
keywords1 = data['main_keywords'] || []

# Загрузите конфигурационный файл
config_data = YAML.load_file('_data/config.yml')
lang = config_data['lang']

# Сформируйте путь к файлу ключевых слов на основе значения shop и lang
keywords2_path = "_data/#{data['shop']}_keywords_#{lang}.yml"
keywords2_data = YAML.load_file(keywords2_path)
keywords2 = keywords2_data['keyword']

# Обработайте все поля в данных
processed_data = process_content(data, keywords1, keywords2)

# Преобразуйте обработанные данные обратно в YAML и запишите в index.md
new_content = processed_data.to_yaml + "---\n"
File.write(index_path, new_content)

# Записываем ключевые слова в файл result.txt
current_directory = File.basename(Dir.getwd)
write_keywords_to_file(current_directory, keywords1)