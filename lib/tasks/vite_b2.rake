# frozen_string_literal: true

namespace :vite do
  desc "Upload public/vite output to Backblaze B2 and strip bulky files on success"
  task upload_to_b2: :environment do
    if B2AssetsStorage.upload_vite_output!
      Rake::Task["vite:strip_from_image"].invoke
    end
  end

  desc "Remove bulky vite output from the image after B2 upload"
  task strip_from_image: :environment do
    B2AssetsStorage.strip_from_image!
  end

  desc "Test Backblaze B2 credentials (list, upload, public read, delete)"
  task test_b2: :environment do
    success = B2AssetsStorage.test_connection!
    exit(1) unless success
  end
end
