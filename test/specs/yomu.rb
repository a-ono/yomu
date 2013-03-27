require_relative '../helper.rb'

describe Yomu do
  let(:data) { File.read 'test/samples/sample.pages' }
  let(:doc) { File.read 'test/samples/enclosure_problem.doc' }

  before do
    ENV['JAVA_HOME'] = nil
  end

  describe '.read' do
    it 'reads text' do
      text = Yomu.read :text, data

      text.should be_include('The quick brown fox jumped over the lazy cat.')
    end

    it 'reads metadata' do
      metadata = Yomu.read :metadata, data

      metadata['Content-Type'].should == 'application/vnd.apple.pages'
    end

    it 'accepts metadata with colon' do
      metadata = Yomu.read :metadata, doc
      metadata['dc:title'].should == 'problem: test'
    end
  end

  describe '.new' do
    it 'requires parameters' do
      expect { Yomu.new }.to raise_error(ArgumentError)
    end

    it 'accepts a root path' do
      yomu = Yomu.new 'test/samples/sample.pages'

      yomu.path?.should be_true
      yomu.uri?.should be_false
      yomu.stream?.should be_false
    end

    it 'accepts a relative path' do
      yomu = Yomu.new 'test/samples/sample.pages'

      yomu.path?.should be_true
      yomu.uri?.should be_false
      yomu.stream?.should be_false
    end

    it 'accepts a path with spaces' do
      yomu = Yomu.new 'test/samples/sample filename with spaces.pages'

      yomu.path?.should be_true
      yomu.uri?.should be_false
      yomu.stream?.should be_false
    end

    it 'accepts a URI' do
      yomu = Yomu.new 'http://svn.apache.org/repos/asf/poi/trunk/test-data/document/sample.docx'

      yomu.uri?.should be_true
      yomu.path?.should be_false
      yomu.stream?.should be_false
    end

    it 'accepts a stream or object that can be read' do
      yomu = File.open 'test/samples/sample.pages', 'r' do |file|
        Yomu.new file
      end

      yomu.stream?.should be_true
      yomu.uri?.should be_false
      yomu.path?.should be_false
    end

    it 'does not accept a path to a missing file' do
      expect { Yomu.new 'test/sample/missing.pages' }.to raise_error(Errno::ENOENT)
    end

    it 'does not accept other objects' do
      [nil, 1, 1.1].each do |object|
        expect { Yomu.new object }.to raise_error(TypeError)
      end
    end
  end

  describe '.java' do
    specify 'with no specified JAVA_HOME' do
      Yomu.send(:java).should == 'java'
    end

    specify 'with a specified JAVA_HOME' do
      ENV['JAVA_HOME'] = '/path/to/java/home'

      Yomu.send(:java).should == '/path/to/java/home/bin/java'
    end
  end

  describe 'initialized with a given path' do
    let(:yomu) { Yomu.new 'test/samples/sample.pages' }

    specify '#text reads text' do
      yomu.text.should be_include('The quick brown fox jumped over the lazy cat.')
    end

    specify '#metada reads metadata' do
      yomu.metadata['Content-Type'].should == 'application/vnd.apple.pages'
    end
  end

  describe 'initialized with a given URI' do
    let(:yomu) { Yomu.new 'http://svn.apache.org/repos/asf/poi/trunk/test-data/document/sample.docx' }

    specify '#text reads text' do
      yomu.text.should be_include('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
    end

    specify '#metadata reads metadata' do
      yomu.metadata['Content-Type'].should == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    end
  end

  describe 'initialized with a given stream' do
    let(:yomu) { Yomu.new File.open('test/samples/sample.pages', 'rb') }

    specify '#text reads text' do
      yomu.text.should be_include('The quick brown fox jumped over the lazy cat.')
    end

    specify '#metadata reads metadata' do
      yomu.metadata['Content-Type'].should == 'application/vnd.apple.pages'
    end
  end
end
