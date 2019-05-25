require 'zlib'

module XjzLoader
  class Packer
    def initialize
      @data = {}
    end

    # path, str
    def add_code(path, str, clear: true)
      str = clean_code(str) if clear
      @data[path] = compile_code(path, str)
    end

    def add_data(path, str)
      @data[path] = str
    end

    def result
      data_str = @data.map do |k, v|
        is_utf8 = v.encoding == Encoding::UTF_8 ? 1 : 0
        [
          [1, k.bytesize].pack("CN"), k,
          [is_utf8, v.bytesize].pack("CN"), v.force_encoding('binary')
        ].join
      end.join

      n = 9 + rand(128)
      [
        [n].pack('C'),
        Random.bytes(n),
        Zlib::Deflate.deflate(data_str),
        Random.bytes(n)
      ].join
    end

    private

    # remove empty line, comment line, and indent
    def clean_code(code)
      code.lines.each_with_object([]) do |line, r|
        next if line =~ /^\s*(#.*)?$/
        line.gsub!(/^\s+/, '')
        r << line
      end.join
    end

    def compile_code(path, code)
      RubyVM::InstructionSequence.compile(
        code, path, path
      ).to_binary
    end
  end
end

