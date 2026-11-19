# These files are required explicitly and do not match Zeitwerk's file-to-constant map.
Rails.autoloaders.main.ignore(
  Rails.root.join('app/helpers/file_upload.rb')
)
