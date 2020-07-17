# frozen_string_literal: true

module Paperclip
  # This converter is only for PNG file
  class PngConverter < Paperclip::Thumbnail
    def make
      if (color_type_2?(file))
        convert_options <<  ' -define png:color-type=2'
      end

      super

    end

    def color_type_2?(file)
      # contains alpha?
      str_identify = identify('-verbose :src', src: File.expand_path(file.path))
      index_ch = str_identify.index('Channel statistics:')
      return false if (index_ch.nil?)
      index_alpha = str_identify.index('Alpha:', index_ch)
      return false if (index_alpha.nil?)
      index_entropy = str_identify.index('entropy:', index_alpha)
      return false if (index_entropy.nil?)
      index_blank = str_identify.index(' ', index_entropy)
      return false if (index_blank.nil?)
      index_entropy_value = index_blank + 1
      str_entropy_value = str_identify[index_entropy_value .. -1]

      # If alpha's entropy is not '0.xx...' (that is '0'),
      # the image does not contain alpha and can be converted 24bit color.
      if (str_entropy_value[1] != '.')
        return true
      end

      return false
    end
  end
end
