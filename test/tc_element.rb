#          Copyright (c) 2006 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'lib/test/test_helper'

include Ramaze

class TCElementController < Template::Ramaze
  def index
    "The index"
  end

  def elementy
    "<Page>#{index}</Page>"
  end

  def nested
    "<Page> some stuff <Page>#{index}</Page> more stuff </Page>"
  end

  def with_params(*params)
    hash = Hash[*params.flatten]
    %{<PageWithParams one="two"></PageWithParams>}
  end
end

class Page < Element
  def render
    %{ <wrap> #{content} </wrap> }
  end
end

class PageWithParams < Element
  def render
    @hash.inspect
  end
end

context "Element" do
  ramaze(:mapping => {'/' => TCElementController})

  specify "simple request" do
    get('/').should == "The index"
  end

  specify "with element" do
    get('/elementy').should == "<wrap> The index </wrap>"
  end

  specify "nested element" do
    get('/nested').should == "<wrap>  some stuff  <wrap> The index </wrap>  more stuff  </wrap>"
  end

  specify "with_params" do
    get('/with_params/one/two').should == {'one' => 'two'}.inspect
  end
end