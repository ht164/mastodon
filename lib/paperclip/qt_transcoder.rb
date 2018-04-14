# frozen_string_literal: true

module Paperclip
  class QtTranscoder < Paperclip::Processor
    def make
      final_file = Paperclip::Transcoder.make(file, options, attachment)

      attachment.instance.file_content_type = 'video/mp4'
      attachment.instance.file_file_name    = File.basename(attachment.instance.file_file_name, '.*') + '.mp4'
      attachment.instance.type              = MediaAttachment.types[:video]

      final_file
    end
  end
end
