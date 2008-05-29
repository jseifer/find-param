require File.join(File.dirname(__FILE__), 'test_helper')

class FindByParamTest < Test::Unit::TestCase
  def setup
    Post.find_param(:slug)
    Post.create(:slug => 'adam-west', :title => 'Adam West')
    Post.create(:slug => 'burt-ward', :title => 'Burt Ward')
  end
  
  def teardown
    Post.delete_all
  end
  
  def test_plugin_loaded_correctly
    assert_kind_of FindByParam::ClassMethods, Post
  end

  def test_find_by_param_was_defined
    assert Post.respond_to?(:find_by_param)
  end

  def test_find_by_param_is_defined_in_subclasses
    assert Blog.respond_to?(:find_by_param)
  end

  def test_returns_valid_data
    post = Post.find_by_param('adam-west')
    assert_equal Post.find_by_slug('adam-west'), post
  end
  
  def test_can_define_find_parameter_with_symbol
    Post.find_param(:title)
    post = Post.find_by_param('Adam West')
    assert_equal Post.find_by_title('Adam West'), post
  end
  
  def test_can_define_find_parameter_with_string
    Post.find_param('title')
    post = Post.find_by_param('Adam West')
    assert_equal Post.find_by_title('Adam West'), post
  end

  def test_correctly_goes_to_param
    post = Post.find_by_slug('adam-west')
    assert_equal 'adam-west', post.to_param
  end
  
  def test_raises_on_not_found_if_specified
    Post.find_param('slug', :raise_on_not_found => true)
    assert_raises ActiveRecord::RecordNotFound do
      Post.find_by_param('non-existent-slug')
    end
  end
  
  def test_raises_column_not_found_error_when_given_undefined_column
    assert_raise(FindByParam::ColumnNotFoundError) do
      Post.find_param(:bad_column_name)
    end
  end

  def test_column_not_found_error_is_a_find_by_param_error
    assert_kind_of FindByParam::Error, FindByParam::ColumnNotFoundError.new
  end
  
  def test_initializes_param_on_create
    Post.find_param(:slug, :initialize_with => :title)
    blog_post = Post.create(:title => 'A Test Post')
    assert_equal 'a-test-post', blog_post.slug
  end

  def test_initializes_param_on_create_using_a_custom_initializer
    Post.find_param(:slug, :initialize_with => :title, :using => Proc.new { |value| value.upcase.gsub(/\s+/, '_') })
    blog_post = Post.create(:title => 'A Test Post')
    assert_equal 'A_TEST_POST', blog_post.slug
  end
end
