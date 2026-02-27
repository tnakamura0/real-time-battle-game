class RoomChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    room = Room.find_by(token: params[:token])

    if room
      stream_for room
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
