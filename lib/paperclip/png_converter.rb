# frozen_string_literal: true

module Paperclip
  # This converter is only for PNG file
  class PngConverter < Paperclip::Thumbnail
    def make
      # contains alpha?
      str_identify = identify('-verbose :src', src: File.expand_path(file.path))
      index_ch = str_identify.index('Channel statistics:')
      index_alpha = str_identify.index('Alpha:', index_ch)
      index_entropy = str_identify.index('entropy:', index_alpha)
      index_entropy_value = str_identify.index(' ', index_entropy) + 1
      str_entropy_value = str_identify[index_entropy_value .. -1]

      # If alpha's entropy is not '0.xx...' (that is '0'),
      # the image does not contain alpha and can be converted 24bit color.
      if (str_entropy_value[1] != '.')
        convert_options <<  ' -define png:color-type=2'
      end

      super

    end
  end
end
