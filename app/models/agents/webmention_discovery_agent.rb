require "nokogiri"
require 'nitlink/response'

module Agents
  class WebmentionDiscoveryAgent < Agent
    include WebRequestConcern

    no_bulk_receive!
    default_schedule "never"

    description <<-MD
      The Webmention Discovery Agent discovers original posts via syndication
      links on a given website and emits a copy of the incoming event with
      additional `webmention_endpoint` and `target_url` properties.

      'source_url' is a Liquid-interpolated string containing the URL of the
      syndicated resource
    MD

    def working?
      true
      # event_created_within?(interpolated['expected_update_period_in_days']) && !recent_error_logs?
    end

    def default_options
      {
        'website' => 'https://updates.kip.pe',
        'source_url' => '{{status.url}}'
      }
    end

    def validate_options
      # errors.add(:base, "expected_update_period_in_days is required") unless options['expected_update_period_in_days'].present?
      # errors.add(:base, "user address is required") if options['user_address'].blank?
      #
      # if options[:include_boosts].present? && !%w[true false].include?(options[:include_boosts])
      #   errors.add(:base, "include_boosts must be a boolean value string (true/false)")
      # end
    end

    def receive(incoming_events)
      # log incoming_events.inspect
      response = faraday.get(options[:website])
      links = parse_http_link_header(response)
      doc = Nokogiri::HTML(response.body)

      webmention_endpoint = discover_webmention_endpoint(links, doc)
      # log "webmention endpoint: " + webmention_endpoint

      incoming_events.each do |event|
        if target_url = discover_target_url(doc, event)
          log "Webmention endpoint: #{webmention_endpoint}, target URL: #{target_url}"
          create_event payload: event.payload.merge({
            "webmention_endpoint": webmention_endpoint,
            "target_url": target_url
          })
        else
          log "No original post found"
        end
      end
    end

    def check
      # needed?
    end

    private

    def parse_http_link_header(response)
      link_parser = Nitlink::Parser.new
      link_parser.parse(response)
    end

    def discover_webmention_endpoint(links, doc)
      if url = links.by_rel('http://webmention.org/').target.to_s
         url = (doc.at_css("link[rel=webmention]") || doc.at_css("a[rel=webmention]"))
        return url
      else
        throw "No webmention endpoint found on website #{options[:website]}"
      end
    end

    def discover_target_url(doc, event)
      mastodon_post_url = event.payload["status"]["url"]

      return nil unless entries = doc.css('.h-entry')

      return nil unless post_entry = entries.select{ |entry|
        el = entry.at_css('.u-syndication.mastodon')
        el ? el.attributes["href"].value == mastodon_post_url : false
      }.first

      if permalink = post_entry.at_css("a.u-url[rel=permalink]")
        permalink.attributes["href"].value
      else
        nil
      end
    end

  end
end
