# Service to convert IndexedContent records to Experience records
# This bridges the gap between metaverse indexer data and the existing Experience system
class MetaverseExperienceImportService
  include Rails.application.routes.url_helpers

  def self.import_from_indexed_content(indexed_content)
    new.import_from_indexed_content(indexed_content)
  end

  def self.bulk_import(indexed_contents)
    new.bulk_import(indexed_contents)
  end

  def import_from_indexed_content(indexed_content)
    # Check if experience already exists for this indexed content
    existing_experience = Experience.find_by(
      indexed_content: indexed_content,
      source_type: "indexed_metaverse"
    )

    if existing_experience
      # Update existing experience with latest data
      update_experience_from_indexed_content(existing_experience, indexed_content)
    else
      # Create new experience from indexed content
      create_experience_from_indexed_content(indexed_content)
    end
  end

  def bulk_import(indexed_contents)
    results = {
      created: 0,
      updated: 0,
      errors: []
    }

    indexed_contents.find_each do |indexed_content|
        experience = import_from_indexed_content(indexed_content)
        if experience.persisted?
          if experience.previously_new_record?
            results[:created] += 1
          else
            results[:updated] += 1
          end
        end
    rescue StandardError => e
        results[:errors] << {
          indexed_content_id: indexed_content.id,
          error: e.message
        }
    end

    results
  end

  private

  def create_experience_from_indexed_content(indexed_content)
    # Find or create a system account for metaverse content
    system_account = find_or_create_system_account

    experience_attributes = build_experience_attributes(indexed_content, system_account)

    Experience.create!(experience_attributes)
  end

  def update_experience_from_indexed_content(experience, indexed_content)
    experience_attributes = build_experience_attributes(indexed_content, experience.account)
    experience_attributes.delete(:account_id) # Don't change account on update

    experience.update!(experience_attributes)
    experience
  end

  def build_experience_attributes(indexed_content, account)
    {
      # Core Experience fields
      title: extract_title(indexed_content),
      description: extract_description(indexed_content),
      author: extract_author(indexed_content),
      account: account,

      # Approval and federation settings
      approved: true, # Auto-approve indexed content
      federate: false, # Never federate indexed content
      offline_available: false, # Metaverse content is online-only

      # Metaverse-specific fields
      source_type: "indexed_metaverse",
      indexed_content: indexed_content,
      metaverse_platform: indexed_content.source_platform,
      metaverse_coordinates: extract_coordinates_json(indexed_content),
      metaverse_metadata: extract_metadata_json(indexed_content)
    }
  end

  def extract_title(indexed_content)
    indexed_content.title.presence ||
      "#{indexed_content.source_platform.titleize} Experience"
  end

  def extract_description(indexed_content)
    description = indexed_content.description.presence ||
                  "Experience from #{indexed_content.source_platform.titleize}"

    # Add coordinate information if available
    description += " at coordinates (#{indexed_content.coordinates['x']}, #{indexed_content.coordinates['y']})" if indexed_content.coordinates.present? && indexed_content.coordinates["x"].present?

    description
  end

  def extract_author(indexed_content)
    indexed_content.author.presence ||
      "#{indexed_content.source_platform.titleize} Creator"
  end

  def extract_coordinates_json(indexed_content)
    return nil if indexed_content.coordinates.blank?

    indexed_content.coordinates.to_json
  end

  def extract_metadata_json(indexed_content)
    metadata = {
      external_id: indexed_content.external_id,
      content_type: indexed_content.content_type,
      last_indexed_at: indexed_content.last_indexed_at,
      source_metadata: indexed_content.metadata
    }

    metadata.to_json
  end

  def find_or_create_system_account
    SystemAccounts.find_or_create_metaverse_import_owner!
  end
end
