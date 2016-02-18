# frozen_string_literal: true
module Geocodable
  module InstanceMethods
    def country
      'Sverige'
    end

    def full_street_address
      [street, zip, country].join(', ')
    end

    def validate_geocoding
      unless geocoded?
        # errors.add(:address, 'must be a valid address')
      end
    end

    def address_changed?
      street_changed? || zip_changed?
    end

    def geocode_zip
      zip_coordinates = Geo.best_coordinates("#{zip}, #{country}")

      self.zip_latitude = zip_coordinates.latitude
      self.zip_longitude = zip_coordinates.longitude
    end

    def geocode_address
      coordinates = Geo.best_coordinates(full_street_address)

      self.latitude = coordinates.latitude
      self.longitude = coordinates.longitude
    end
  end

  def self.included(receiver)
    receiver.class_eval do
      geocoded_by :full_street_address
      geocoded_by :zip, latitude: :zip_latitude, longitude: :zip_longitude

      after_validation :geocode_address, if: ->(record) { record.address_changed? }
      after_validation :geocode_zip, if: ->(record) { record.zip_changed? }
      after_validation :validate_geocoding

      def self.within(lat:, long:, distance:, locate_type: :address)
        type = self::LOCATE_BY.fetch(locate_type)
        near(
          [lat, long],
          distance,
          latitude: type[:lat],
          longitude: type[:long],
          units: :km
        )
      end
    end
    receiver.send(:include, InstanceMethods)
  end
end
