require 'xjz_loader/packer'

RSpec.describe XjzLoader do
  let(:root_path) { File.join(XjzLoader.gem_dir, 'tmp') }
  let(:data_path) { File.join(root_path, 'data') }
  let(:code_files) do
    [
      ['boot.rb', '$td[:b] = 233'],
      ['code.rb', '$td[:c] = 123'],
      ['c2.rb', '$td[:c2] = 321']
    ]
  end
  let(:result) { {} }
  let(:packer) { XjzLoader::Packer.new }

  before :each do
    $td = result
    allow(XjzLoader).to receive(:root).and_return(root_path)
  end

  it "has a version number" do
    expect(XjzLoader::VERSION).not_to be nil
  end

  it '.get_res/.load_file should not crash when load invalid path' do
    packer.add_data('str', 'hello world')
    code_files.each { |p, s| packer.add_code(p, s) }

    File.write(data_path, packer.result)
    XjzLoader.start

    expect(XjzLoader.get_res('asdf')).to eql(nil)
    expect(XjzLoader.load_file('asdfdsfa')).to eql(false)
  end

  it '.load_file should support prefix xjz, ./, and root path' do
    packer.add_data('str', 'hello world')
    code_files.each { |p, s| packer.add_code(p, s) }
    packer.add_code('src/xjz/a.rb', '$td[:a] = "aaa"')
    packer.add_code('src/xjz/b.rb', '$td[:bb] = "bbb"')
    packer.add_code('src/xjz/c.rb', '$td[:ccc] = "cc"')

    File.write(data_path, packer.result)
    XjzLoader.start

    expect {
      expect(XjzLoader.load_file('xjz/a.rb')).to eql(true)
    }.to change { result[:a] }.to('aaa')

    expect {
      expect(XjzLoader.load_file('./src/xjz/b.rb')).to eql(true)
    }.to change { result[:bb] }.to('bbb')

    expect {
      abs_path = File.join(root_path, 'src/xjz/c.rb')
      expect(XjzLoader.load_file(abs_path)).to eql(true)
    }.to change { result[:ccc] }.to('cc')
  end

  it '.load_file should avoid loop load' do
    packer.add_data('str', 'hello world')
    packer.add_code('boot.rb', '($td[:a] ||= []) << 1; XjzLoader.load_file("app");')
    packer.add_code('app.rb', '($td[:a] ||= []) << 2; XjzLoader.load_file("boot");')
    packer.add_code('a.rb', '($td[:a] ||= []) << 3; XjzLoader.load_file("b");')
    packer.add_code('b.rb', '($td[:a] ||= []) << 4; XjzLoader.load_file("a");')

    File.write(data_path, packer.result)

    expect { XjzLoader.start }.to change { result[:a] }.to([1, 2])
    expect { XjzLoader.load_file('a') }.to change { result[:a] }.to([1, 2, 3, 4])
    expect { XjzLoader.load_file('a') }.to_not change { result[:a] }
    expect { XjzLoader.load_file('b') }.to_not change { result[:a] }
  end

  it '.has_reg? should return path if exist' do
    code_files.each { |p, s| packer.add_code(p, s) }
    packer.add_data('dir/a', '1')
    packer.add_data('dir/b', '2')
    packer.add_data('dir/c', '3')

    File.write(data_path, packer.result)
    XjzLoader.start

    expect(XjzLoader.has_res?('dir/a')).to eql('dir/a')
    expect(XjzLoader.has_res?('dir/aa')).to eql(nil)
    expect(XjzLoader.has_res?(/^dir/)).to eql('dir/a')
    expect(XjzLoader.has_res?(/^dir\/(b|c)/)).to eql('dir/b')
    expect(XjzLoader.has_res?(/^dir\/dd/)).to eql(nil)
  end
end
