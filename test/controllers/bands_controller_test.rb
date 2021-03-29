require 'test_helper'

class BandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @band = bands(:one)
  end

  test "should get index" do
    get bands_url
    assert_response :success
  end

  test "should get new" do
    get new_band_url
    assert_response :success
  end

  test "should create band" do
    assert_difference('Band.count') do
      post bands_url, params: { band: { description: @band.description, name: @band.name, photo: @band.photo, playing_next: @band.playing_next, song: @band.song, when_playing_next: @band.when_playing_next } }
    end

    assert_redirected_to band_url(Band.last)
  end

  test "should show band" do
    get band_url(@band)
    assert_response :success
  end

  test "should get edit" do
    get edit_band_url(@band)
    assert_response :success
  end

  test "should update band" do
    patch band_url(@band), params: { band: { description: @band.description, name: @band.name, photo: @band.photo, playing_next: @band.playing_next, song: @band.song, when_playing_next: @band.when_playing_next } }
    assert_redirected_to band_url(@band)
  end

  test "should destroy band" do
    assert_difference('Band.count', -1) do
      delete band_url(@band)
    end

    assert_redirected_to bands_url
  end
end
