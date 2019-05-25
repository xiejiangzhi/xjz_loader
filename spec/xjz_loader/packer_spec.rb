require 'xjz_loader/packer'

RSpec.describe XjzLoader::Packer do
  let(:root_path) { File.expand_path('../../../tmp', __FILE__) }
  let(:data_path) { File.join(root_path, 'data') }
  let(:code_files) do
    [
      ['boot.rb', '$td[:b] = 233'],
      ['code.rb', '$td[:c] = 123'],
      ['c2.rb', '$td[:c2] = 321']
    ]
  end
  let(:result) { {} }

  before :each do
    $td = result end

  it 'pack and load should working' do
    subject.add_data('str', 'hello world')
    code_files.each { |p, s| subject.add_code(p, s) }

    data = subject.result
    expect(data).to be_a(String)

    File.write(data_path, data)
    allow(XjzLoader).to receive(:root).and_return(root_path)

    expect {
      XjzLoader.start
    }.to change { result[:b] }.to(233)

    expect {
      expect(XjzLoader.load_file('code')).to eql(true)
    }.to change { result[:c] }.to(123)

    result[:c] = 111
    expect {
      expect {
        XjzLoader.load_all
      }.to_not change { result[:c] }
    }.to change { result[:c2] }.to(321)

    expect(XjzLoader.get_res('str')).to eql('hello world')
  end

  it 'should not crash when load invalid path' do
    subject.add_data('str', 'hello world')
    code_files.each { |p, s| subject.add_code(p, s) }

    data = subject.result
    expect(data).to be_a(String)

    File.write(data_path, data)
    allow(XjzLoader).to receive(:root).and_return(root_path)

    XjzLoader.start
    expect(XjzLoader.get_res('asdf')).to eql(nil)
    expect(XjzLoader.load_file('asdfdsfa')).to eql(false)
  end

  it 'should support prefix xjz, ./, and root path' do
    subject.add_data('str', 'hello world')
    code_files.each { |p, s| subject.add_code(p, s) }
    subject.add_code('src/xjz/a.rb', '$td[:a] = "aaa"')
    subject.add_code('src/xjz/b.rb', '$td[:bb] = "bbb"')
    subject.add_code('src/xjz/c.rb', '$td[:ccc] = "cc"')

    data = subject.result
    expect(data).to be_a(String)

    File.write(data_path, data)
    allow(XjzLoader).to receive(:root).and_return(root_path)

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
end
