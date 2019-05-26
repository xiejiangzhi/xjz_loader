require 'xjz_loader/packer'

RSpec.describe XjzLoader::Packer do
  let(:root_path) { File.join(XjzLoader.gem_dir, 'tmp') }
  let(:data_path) { File.join(root_path, 'data') }
  let(:result) { {} }

  before :each do
    $td = result
  end

  it 'pack and load should working' do
    subject.add_data('str', 'hello world')
    [
      ['boot.rb', '$td[:b] = 233'],
      ['code.rb', '$td[:c] = 123'],
      ['c2.rb', '$td[:c2] = 321']
    ].each do |p, s|
      subject.add_code(p, s)
    end

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

    # loaded code was removed, so cannot load again
    expect(XjzLoader.load_file('code')).to eql(false)

    result[:c] = 111
    expect {
      expect {
        XjzLoader.load_all
      }.to_not change { result[:c] }
    }.to change { result[:c2] }.to(321)

    expect(XjzLoader.get_res('str')).to eql('hello world')
  end
end
