module ErrorSerializer

  def ErrorSerializer.serialize(errors)
    return if errors.nil?

    json = {}
    error_messages = []
    errors.to_hash.each do |k, v|
      error_messages << { id: k, title: v[0] }
    end
    json[:errors] = error_messages
    json
  end

end

