require 'test_helper'

class BandGenresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @band_genre = band_genres(:one)
  end

  test "should get index" do
    get band_genres_url
    assert_response :success
  end

  test "should get new" do
    get new_band_genre_url
    assert_response :success
  end

  test "should create band_genre" do
    assert_difference('BandGenre.count') do
      post band_genres_url, params: { band_genre: { band_id: @band_genre.band_id, genre_id: @band_genre.genre_id } }
    end

    assert_redirected_to band_genre_url(BandGenre.last)
  end

  test "should show band_genre" do
    get band_genre_url(@band_genre)
    assert_response :success
  end

  test "should get edit" do
    get edit_band_genre_url(@band_genre)
    assert_response :success
  end

  test "should update band_genre" do
    patch band_genre_url(@band_genre), params: { band_genre: { band_id: @band_genre.band_id, genre_id: @band_genre.genre_id } }
    assert_redirected_to band_genre_url(@band_genre)
  end

  test "should destroy band_genre" do
    assert_difference('BandGenre.count', -1) do
      delete band_genre_url(@band_genre)
    end

    assert_redirected_to band_genres_url
  end
end
