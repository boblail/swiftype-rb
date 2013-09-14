require 'swiftype/configuration'
require 'swiftype/result_set'
require 'swiftype/request'

module Swiftype
  class Client

    include Swiftype::Request

    # Create a new Swiftype::Client client
    #
    # @param options [Hash] a hash of configuration options that will overrided what is set on the Swiftype class.
    # @option options [String] :api_key an API Key to use for this client
    # @option options [String] :platform_access_token a user's access token, will be used instead of API key for authenticating requests
    def initialize(options={})
      @options = options
    end

    def api_key
      @options[:api_key] || Swiftype.api_key
    end

    def platform_access_token
      @options[:platform_access_token]
    end

    module User

      # List users for the configured application.
      #
      # @param options [Hash]
      # @option options [Integer] :page page number of users to fetch (server defaults to 1)
      # @option options [Integer] :per_page users to return per page (server defaults to 50)
      def users(options={})
        params = {
          :client_id => Swiftype.platform_client_id,
          :client_secret => Swiftype.platform_client_secret
        }
        get("users.json", params.merge(options))
      end

      # Create a new user for the configured application.
      def create_user
        params = {
          :client_id => Swiftype.platform_client_id,
          :client_secret => Swiftype.platform_client_secret
        }
        post("users.json", params)
      end

      # Return a user created by the configured application.
      #
      # @param user_id [String] the Swiftype User ID
      def user(user_id)
        params = {
          :client_id => Swiftype.platform_client_id,
          :client_secret => Swiftype.platform_client_secret
        }
        get("users/#{user_id}.json", params)
      end
    end

    module Engine
      def engines
        get("engines.json")
      end

      def engine(engine_id)
        get("engines/#{engine_id}.json")
      end

      def create_engine(name)
        post("engines.json", :engine => {:name => name})
      end

      def destroy_engine(engine_id)
        delete("engines/#{engine_id}.json")
      end

      # Perform an autocomplete (prefix) search over all the DocumentTypes of the provided engine.
      # This can be used to implement type-ahead autocompletion. However, if your data is not sensitive,
      # you should consider using the {Swiftype public JSONP API}[https://swiftype.com/documentation/public_api]
      # in the user's web browser for suggest queries.
      #
      #     results = client.suggest("swiftype-api-example", "gla")
      #     results['videos'] # => [{'external_id' => 'v1uyQZNg2vE', 'title' => 'How It Feels [through Glass]', ...}, ...]
      #
      # @param [String] engine_id the Engine slug or ID
      # @param [String] query the search terms
      # @param [Hash] options search options (see {the REST API docs}[https://swiftype.com/documentation/searching] for a complete list)
      # @option options [Integer] :page page number of results to fetch (server defaults to 1)
      # @option options [Integer] :per_page number of results per page (server defaults to 20)
      # @option options [Array] :document_types an array of DocumentType slugs to search.
      #   The server defaults to searching all DocumentTypes in the engine. To search a single document type,
      #   the +suggest_document_type+ method is more convenient.
      # @option options [Hash] :fetch_fields a Hash of DocumentType slug to array of the fields to return with results
      #   (example: <code>{'videos' => ['title', 'channel_id']}</code>)
      # @option options [Hash] :search_fields a Hash of DocumentType slug to array of the fields to search.
      #   May contain {field weight boosts}[https://swiftype.com/documentation/searching#field_weights]
      #   (example: <code>{'videos' => ['title^5', 'tags^2', 'caption']}</code>).
      #   The server defaults to searching all +string+ fields for suggest queries.
      # @option options [Hash] :filters a Hash of DocumentType slug to filter definition Hash.
      #   See {filters in the REST API documentation}[https://swiftype.com/documentation/searching#filters] for more details
      #   (example: <code>{'videos' => {'category_id' => ['23', '25']}}</code>)
      # @option options [Hash] :functional_boosts a Hash of DocumentType slug to {functional boost}[https://swiftype.com/documentation/searching#functional_boosts] definition
      #   (example: <code>{'videos' => {'view_count' => 'logarithmic'}}</code>).
      # @option options [Hash] :sort_field a Hash of DocumentType slug to field name to sort on
      #   (example: <code>{'videos' => 'view_count'}</code>)
      # @option options [Hash] :sort_direction a Hash of DocumentType slug to direction to sort
      #   (example: <code>'videos' => 'desc'</code>). Usually used with +:sort_field+.
      #
      # @return [Swiftype::ResultSet]
      def suggest(engine_id, query, options={})
        search_params = { :q => query }.merge(options)
        response = post("engines/#{engine_id}/suggest.json", search_params)
        ResultSet.new(response)
      end

      # Perform a full-text search over all the DocumentTypes of the provided engine.
      #
      #     results = client.search("swiftype-api-example", "glass")
      #     results['videos'] # => [{'external_id' => 'v1uyQZNg2vE', 'title' => 'How It Feels [through Glass]', ...}, ...]
      #
      # @param [String] engine_id the Engine slug or ID
      # @param [String] query the search terms (may be nil)
      # @param [Hash] options search options (see {the REST API docs}[https://swiftype.com/documentation/searching] for a complete list)
      # @option options [Integer] :page page number of results to fetch (server defaults to 1)
      # @option options [Integer] :per_page number of results per page (server defaults to 20)
      # @option options [Array] :document_types an array of DocumentType slugs to search.
      #   The server defaults to searching all DocumentTypes in the engine. To search a single document type,
      #   the +search_document_type+ method is more convenient.
      # @option options [Hash] :fetch_fields a Hash of DocumentType slug to array of the fields to return with results
      #   (example: <code>{'videos' => ['title', 'channel_id']}</code>)
      # @option options [Hash] :search_fields a Hash of DocumentType slug to array of the fields to search.
      #   May contain {field weight boosts}[https://swiftype.com/documentation/searching#field_weights]
      #   (example: <code>{'videos' => ['title^5', 'tags^2', 'caption']}</code>).
      #   The server defaults to searching all +string+ and +text+ fields for search queries.
      # @option options [Hash] :filters a Hash of DocumentType slug to filter definition Hash.
      #   See {filters in the REST API documentation}[https://swiftype.com/documentation/searching#filters] for more details
      #   (example: <code>{'videos' => {'category_id' => ['23', '25']}}</code>)
      # @option options [Hash] :functional_boosts a Hash of DocumentType slug to {functional boost}[https://swiftype.com/documentation/searching#functional_boosts] definition
      #   (example: <code>{'videos' => {'view_count' => 'logarithmic'}}</code>).
      # @option options [Hash] :facets a Hash of DocumentType slug to an Array of field names to provide facetted counts for
      #   (example: <code>{'videos' => ['category_id', 'channel_id']}</code>)
      # @option options [Hash] :sort_field a Hash of DocumentType slug to field name to sort on
      #   (example: <code>{'videos' => 'view_count'}</code>)
      # @option options [Hash] :sort_direction a Hash of DocumentType slug to direction to sort
      #   (example: <code>'videos' => 'desc'</code>). Usually used with +:sort_field+.
      #
      # @return [Swiftype::ResultSet]
      def search(engine_id, query, options={})
        search_params = { :q => query }.merge(options)
        response = post("engines/#{engine_id}/search.json", search_params)
        ResultSet.new(response)
      end
    end

    module DocumentType
      def document_types(engine_id)
        get("engines/#{engine_id}/document_types.json")
      end

      def document_type(engine_id, document_type_id)
        get("engines/#{engine_id}/document_types/#{document_type_id}.json")
      end

      def create_document_type(engine_id, name)
        post("engines/#{engine_id}/document_types.json", :document_type => {:name => name})
      end

      def destroy_document_type(engine_id, document_type_id)
        delete("engines/#{engine_id}/document_types/#{document_type_id}.json")
      end

      # Perform an autocomplete (prefix) search over a single DocumentType in an Engine.
      # This can be used to implement type-ahead autocompletion. However, if your data is not sensitive,
      # you should consider using the {Swiftype public JSONP API}[https://swiftype.com/documentation/public_api]
      # in the user's web browser for suggest queries.
      #
      #     results = client.suggest_document_type("swiftype-api-example", "videos", "gla")
      #     results['videos'] # => [{'external_id' => 'v1uyQZNg2vE', 'title' => 'How It Feels [through Glass]', ...}, ...]
      #
      # @param [String] engine_id the Engine slug or ID
      # @param [String] query the search terms
      # @param [Hash] options search options (see {the REST API docs}[https://swiftype.com/documentation/searching] for a complete list)
      # @option options [Integer] :page page number of results to fetch (server defaults to 1)
      # @option options [Integer] :per_page number of results per page (server defaults to 20)
      # @option options [Array] :document_types an array of DocumentType slugs to search.
      #   The server defaults to searching all DocumentTypes in the engine. To search a single document type,
      #   the +suggest_document_type+ method is more convenient.
      # @option options [Hash] :fetch_fields a Hash of DocumentType slug to array of the fields to return with results
      #   (example: <code>{'videos' => ['title', 'channel_id']}</code>)
      # @option options [Hash] :search_fields a Hash of DocumentType slug to array of the fields to search.
      #   May contain {field weight boosts}[https://swiftype.com/documentation/searching#field_weights]
      #   (example: <code>{'videos' => ['title^5', 'tags^2', 'caption']}</code>).
      #   The server defaults to searching all +string+ fields for suggest queries.
      # @option options [Hash] :filters a Hash of DocumentType slug to filter definition Hash.
      #   See {filters in the REST API documentation}[https://swiftype.com/documentation/searching#filters] for more details
      #   (example: <code>{'videos' => {'category_id' => ['23', '25']}}</code>)
      # @option options [Hash] :functional_boosts a Hash of DocumentType slug to {functional boost}[https://swiftype.com/documentation/searching#functional_boosts] definition
      #   (example: <code>{'videos' => {'view_count' => 'logarithmic'}}</code>).
      # @option options [Hash] :sort_field a Hash of DocumentType slug to field name to sort on
      #   (example: <code>{'videos' => 'view_count'}</code>)
      # @option options [Hash] :sort_direction a Hash of DocumentType slug to direction to sort
      #   (example: <code>'videos' => 'desc'</code>). Usually used with +:sort_field+.
      #
      # @return [Swiftype::ResultSet]
      def suggest_document_type(engine_id, document_type_id, query, options={})
        search_params = { :q => query }.merge(options)
        response = post("engines/#{engine_id}/document_types/#{document_type_id}/suggest.json", search_params)
        ResultSet.new(response)
      end

      # Perform a full-text search over a single DocumentType in an Engine.
      #
      #     results = client.search_document_type("swiftype-api-example", "videos", "glass")
      #     results['videos'] # => [{'external_id' => 'v1uyQZNg2vE', 'title' => 'How It Feels [through Glass]', ...}, ...]
      #
      # @param [String] engine_id the Engine slug or ID
      # @param [String] document_type_id the DocumentType slug or ID
      # @param [String] query the search terms (may be nil)
      # @param [Hash] options search options (see {the REST API docs}[https://swiftype.com/documentation/searching] for a complete list)
      # @option options [Integer] :page page number of results to fetch (server defaults to 1)
      # @option options [Integer] :per_page number of results per page (server defaults to 20)
      # @option options [Hash] :fetch_fields a Hash of DocumentType slug to array of the fields to return with results
      #   (example: <code>{'videos' => ['title', 'channel_id']}</code>)
      # @option options [Hash] :search_fields a Hash of DocumentType slug to array of the fields to search.
      #   May contain {field weight boosts}[https://swiftype.com/documentation/searching#field_weights]
      #   (example: <code>{'videos' => ['title^5', 'tags^2', 'caption']}</code>).
      #   The server defaults to searching all +string+ and +text+ fields for search queries.
      # @option options [Hash] :filters a Hash of DocumentType slug to filter definition Hash.
      #   See {filters in the REST API documentation}[https://swiftype.com/documentation/searching#filters] for more details
      #   (example: <code>{'videos' => {'category_id' => ['23', '25']}}</code>)
      # @option options [Hash] :functional_boosts a Hash of DocumentType slug to {functional boost}[https://swiftype.com/documentation/searching#functional_boosts] definition
      #   (example: <code>{'videos' => {'view_count' => 'logarithmic'}}</code>).
      # @option options [Hash] :facets a Hash of DocumentType slug to an Array of field names to provide facetted counts for
      #   (example: <code>{'videos' => ['category_id', 'channel_id']}</code>)
      # @option options [Hash] :sort_field a Hash of DocumentType slug to field name to sort on
      #   (example: <code>{'videos' => 'view_count'}</code>)
      # @option options [Hash] :sort_direction a Hash of DocumentType slug to direction to sort
      #   (example: <code>'videos' => 'desc'</code>). Usually used with +:sort_field+.
      #
      # @return [Swiftype::ResultSet]
      def search_document_type(engine_id, document_type_id, query, options={})
        search_params = { :q => query }.merge(options)
        response = post("engines/#{engine_id}/document_types/#{document_type_id}/search.json", search_params)
        ResultSet.new(response)
      end
    end

    module Document
      def documents(engine_id, document_type_id, page=nil, per_page=nil)
        options = {}
        options[:page] = page if page
        options[:per_page] = per_page if per_page
        get("engines/#{engine_id}/document_types/#{document_type_id}/documents.json", options)
      end

      def document(engine_id, document_type_id, document_id)
        get("engines/#{engine_id}/document_types/#{document_type_id}/documents/#{document_id}.json")
      end

      def create_document(engine_id, document_type_id, document={})
        post("engines/#{engine_id}/document_types/#{document_type_id}/documents.json", :document => document)
      end

      def create_documents(engine_id, document_type_id, documents=[])
        post("engines/#{engine_id}/document_types/#{document_type_id}/documents/bulk_create.json", :documents => documents)
      end

      def destroy_document(engine_id, document_type_id, document_id)
        delete("engines/#{engine_id}/document_types/#{document_type_id}/documents/#{document_id}.json")
      end

      def destroy_documents(engine_id, document_type_id, document_ids=[])
        post("engines/#{engine_id}/document_types/#{document_type_id}/documents/bulk_destroy.json", :documents => document_ids)
      end

      def create_or_update_document(engine_id, document_type_id, document={})
        post("engines/#{engine_id}/document_types/#{document_type_id}/documents/create_or_update.json", :document => document)
      end

      def create_or_update_documents(engine_id, document_type_id, documents=[])
        post("engines/#{engine_id}/document_types/#{document_type_id}/documents/bulk_create_or_update.json", :documents => documents)
      end

      def update_document(engine_id, document_type_id, document_id, fields)
        put("engines/#{engine_id}/document_types/#{document_type_id}/documents/#{document_id}/update_fields.json", { :fields => fields })
      end

      def update_documents(engine_id, document_type_id, documents={})
        put("engines/#{engine_id}/document_types/#{document_type_id}/documents/bulk_update.json", { :documents => documents })
      end
    end

    module Analytics
      def analytics_searches(engine_id, from=nil, to=nil)
        get("engines/#{engine_id}/analytics/searches.json", date_range(from, to))
      end

      def analytics_autoselects(engine_id, from=nil, to=nil)
        get("engines/#{engine_id}/analytics/autoselects.json", date_range(from, to))
      end

      # Return top queries for an engine.
      #
      # @param [String] engine_id the engine slug or ID
      # @param [Hash] options
      # @option options [String] :start_date a date formatted like '2013-01-01'
      # @option options [String] :end_date a date formatted like '2013-01-01'
      # @option options [Integer] :page page number (0-based). The server defaults to page 0 and the maximum is 50.
      # @option options [Integer] :per_page number of results per page. The server defaults to 20 and the maximum is 100.
      def analytics_top_queries(engine_id, options={})
        get("engines/#{engine_id}/analytics/top_queries.json", options)
      end

      # Return top queries with no results for an engine.
      #
      # @param [String] engine_id the engine slug or ID
      # @param [Hash] options
      # @option options [String] :start_date a date formatted like '2013-01-01'
      # @option options [String] :end_date a date formatted like '2013-01-01'
      # @option options [Integer] :page page number (0-based). The server defaults to page 0 and the maximum is 50.
      # @option options [Integer] :per_page number of results per page. The server defaults to 20 and the maximum is 100.
      def analytics_top_no_result_queries(engine_id, options={})
        get("engines/#{engine_id}/analytics/top_no_result_queries.json", options)
      end

      private
      def date_range(from, to)
        options = {}
        options[:start_date] = from if from
        options[:end_date] = to if to
        options
      end
    end

    module Domain
      def domains(engine_id)
        get("engines/#{engine_id}/domains.json")
      end

      def domain(engine_id, domain_id)
        get("engines/#{engine_id}/domains/#{domain_id}.json")
      end

      def create_domain(engine_id, url)
        post("engines/#{engine_id}/domains.json", {:domain => {:submitted_url => url}})
      end

      def destroy_domain(engine_id, domain_id)
        delete("engines/#{engine_id}/domains/#{domain_id}.json")
      end

      def recrawl_domain(engine_id, domain_id)
        put("engines/#{engine_id}/domains/#{domain_id}/recrawl.json")
      end

      def crawl_url(engine_id, domain_id, url)
        put("engines/#{engine_id}/domains/#{domain_id}/crawl_url.json", {:url => url})
      end
    end

    module Clickthrough
      def log_clickthrough(engine_id, document_type, q, id)
        post(
          "engines/#{engine_id}/document_types/#{document_type}/analytics/log_clickthrough.json",
          {:q => q, :id => id}
        )
      end
    end

    include Swiftype::Client::User
    include Swiftype::Client::Engine
    include Swiftype::Client::DocumentType
    include Swiftype::Client::Document
    include Swiftype::Client::Analytics
    include Swiftype::Client::Domain
    include Swiftype::Client::Clickthrough
  end
end
