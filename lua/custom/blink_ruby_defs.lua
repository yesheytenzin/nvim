local M = {}

local ok_query, query = pcall(
  vim.treesitter.query.parse,
  "ruby",
  [[
  (method name: (_) @def parameters: (method_parameters)? @params)
  (singleton_method name: (_) @def parameters: (method_parameters)? @params)
  (class name: (_) @classdef)
  (module name: (_) @classdef)
  (program (call
    method: (identifier) @kind (#any-of? @kind "require" "require_relative")
    arguments: (argument_list . (string (string_content) @path))))
]]
)

local cache = {}

local function empty_result()
  return { defs = {}, requires = {}, classes = {} }
end

local function scan(source)
  if not ok_query or not query then
    return empty_result()
  end
  -- String parser needs the ruby parser installed; fail soft so blink
  -- still calls back (buffer source then acts as fallback).
  local ok_parser, parser = pcall(vim.treesitter.get_string_parser, source, "ruby")
  if not ok_parser or not parser then
    return empty_result()
  end
  local ok_parse, trees = pcall(function()
    return parser:parse()
  end)
  if not ok_parse or not trees or not trees[1] then
    return empty_result()
  end
  local defs, requires, classes = {}, {}, {}
  local last_def
  local ok_iter = pcall(function()
    for id, node in query:iter_captures(trees[1]:root(), source) do
      local capture = query.captures[id]
      local ok_text, text = pcall(vim.treesitter.get_node_text, node, source)
      if ok_text and text then
        if capture == "classdef" then
          -- `class User`, `module Admin`: needed for `class_name: 'User'`
          -- string values + bare constant completion. Scoped name keeps
          -- `Admin::User` intact instead of just `User`.
          classes[#classes + 1] = { name = text }
          local parent = node:parent()
          local grand = parent and parent:parent()
          last_def = { name = text, params = "", top = grand ~= nil and grand:type() == "program" }
          defs[#defs + 1] = last_def
        elseif capture == "params" and last_def then
          last_def.params = text
        elseif capture == "kind" then
          requires[#requires + 1] = { kind = text }
        elseif capture == "path" and #requires > 0 then
          requires[#requires].path = text
        end
      end
    end
  end)
  if not ok_iter then
    return empty_result()
  end
  return { defs = defs, requires = requires, classes = classes }
end

local function mtime_key(stat)
  -- sec granularity caused stale hits after quick :w/:wq cycles.
  return string.format("%d.%09d:%d", stat.mtime.sec, stat.mtime.nsec or 0, stat.size)
end

local function scan_file(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end
  local key = mtime_key(stat)
  local hit = cache[path]
  if hit and hit.key == key then
    return hit.result
  end
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local content = fd:read("*a")
  fd:close()
  -- Never let a broken required file kill the whole completion callback.
  local ok, result = pcall(scan, content or "")
  if not ok or not result then
    return nil
  end
  cache[path] = { key = key, result = result }
  return result
end

local buffer_cache = {}

-- Static Rails / Ruby DSL keywords. ruby-lsp only suggests these after
-- indexing finishes (often seconds after open / :w), so `belongs_to`,
-- `has_many`, `validates`, … were missing from blink right when you need
-- them. This always-on list guarantees they complete instantly, LSP or not.
local RAILS_DSL = {
  -- ActiveRecord associations
  { word = "belongs_to", detail = "Rails: belongs_to :name", doc = "belongs_to :author, optional: true" },
  { word = "has_many", detail = "Rails: has_many :names", doc = "has_many :posts, dependent: :destroy" },
  { word = "has_one", detail = "Rails: has_one :name", doc = "has_one :profile, dependent: :destroy" },
  { word = "has_and_belongs_to_many", detail = "Rails: HABTM", doc = "has_and_belongs_to_many :tags" },
  -- Validations
  { word = "validates", detail = "Rails: validates :attr", doc = "validates :email, presence: true, uniqueness: true" },
  { word = "validate", detail = "Rails: custom validate", doc = "validate :must_be_valid" },
  { word = "validates_with", detail = "Rails: validator class", doc = "validates_with EmailValidator" },
  -- Callbacks
  { word = "before_validation", detail = "Rails callback", doc = "before_validation :strip_whitespace" },
  { word = "after_validation", detail = "Rails callback", doc = "after_validation :report" },
  { word = "before_save", detail = "Rails callback", doc = "before_save :ensure_defaults" },
  { word = "around_save", detail = "Rails callback", doc = "around_save :wrap_save" },
  { word = "after_save", detail = "Rails callback", doc = "after_save :clear_cache" },
  { word = "before_create", detail = "Rails callback", doc = "before_create :generate_token" },
  { word = "after_create", detail = "Rails callback", doc = "after_create :send_welcome" },
  { word = "before_update", detail = "Rails callback", doc = "before_update :touch_edited" },
  { word = "after_update", detail = "Rails callback", doc = "after_update :reindex" },
  { word = "before_destroy", detail = "Rails callback", doc = "before_destroy :guard_destroy" },
  { word = "after_destroy", detail = "Rails callback", doc = "after_destroy :cleanup" },
  { word = "after_commit", detail = "Rails callback", doc = "after_commit :publish, on: :create" },
  { word = "after_rollback", detail = "Rails callback", doc = "after_rollback :notify" },
  -- Models / querying
  { word = "scope", detail = "Rails: scope :name", doc = "scope :published, -> { where(published: true) }" },
  { word = "enum", detail = "Rails: enum status:", doc = "enum :status, { active: 0, archived: 1 }" },
  { word = "delegate", detail = "Rails: delegate :m to:", doc = "delegate :email, to: :user, prefix: true" },
  { word = "accepts_nested_attributes_for", detail = "Rails nested form", doc = "accepts_nested_attributes_for :posts" },
  { word = "serialize", detail = "Rails: serialize :col", doc = "serialize :tags, coder: JSON" },
  { word = "store", detail = "Rails: store :col", doc = "store :settings, accessors: [:theme]" },
  -- Controllers / filters
  { word = "before_action", detail = "Rails filter", doc = "before_action :authenticate_user!" },
  { word = "after_action", detail = "Rails filter", doc = "after_action :log_request" },
  { word = "around_action", detail = "Rails filter", doc = "around_action :wrap_action" },
  { word = "skip_before_action", detail = "Rails filter", doc = "skip_before_action :auth, only: :index" },
  { word = "rescue_from", detail = "Rails: rescue_from Err", doc = "rescue_from ActiveRecord::RecordNotFound, with: :not_found" },
  -- Migrations / schema
  { word = "create_table", detail = "Migration", doc = "create_table :posts do |t| … end" },
  { word = "change_table", detail = "Migration", doc = "change_table :posts do |t| … end" },
  { word = "add_column", detail = "Migration", doc = "add_column :posts, :title, :string" },
  { word = "remove_column", detail = "Migration", doc = "remove_column :posts, :title" },
  { word = "add_index", detail = "Migration", doc = "add_index :posts, :slug, unique: true" },
  { word = "add_reference", detail = "Migration", doc = "add_reference :posts, :user, foreign_key: true" },
  { word = "add_foreign_key", detail = "Migration", doc = "add_foreign_key :posts, :users" },
  -- Ruby core DSL often typed in Rails files
  { word = "attr_accessor", detail = "Ruby: attr_accessor :x", doc = "attr_accessor :name" },
  { word = "attr_reader", detail = "Ruby: attr_reader :x", doc = "attr_reader :name" },
  { word = "attr_writer", detail = "Ruby: attr_writer :x", doc = "attr_writer :name" },
  { word = "private", detail = "Ruby visibility", doc = "private" },
  { word = "protected", detail = "Ruby visibility", doc = "protected" },
  { word = "include", detail = "Ruby: include Mod", doc = "include Comparable" },
  { word = "extend", detail = "Ruby: extend Mod", doc = "extend ActiveSupport::Concern" },
  { word = "prepend", detail = "Ruby: prepend Mod", doc = "prepend Overrides" },
  { word = "require", detail = "Ruby: require \"x\"", doc = "require \"json\"" },
  { word = "require_relative", detail = "Ruby", doc = "require_relative \"../helper\"" },
  { word = "frozen_string_literal", detail = "magic comment", doc = "# frozen_string_literal: true" },
  -- ActiveRecord querying (chainable + finders)
  { word = "where", detail = "AR: where(cond)", doc = "where(published: true).order(created_at: :desc)" },
  { word = "order", detail = "AR: order(...)", doc = "order(created_at: :desc)" },
  { word = "limit", detail = "AR: limit(n)", doc = "limit(10)" },
  { word = "offset", detail = "AR: offset(n)", doc = "offset(20)" },
  { word = "select", detail = "AR: select(...)", doc = "select(:id, :name)" },
  { word = "distinct", detail = "AR: distinct", doc = "distinct.pluck(:email)" },
  { word = "group", detail = "AR: group(...)", doc = "group(:status).count" },
  { word = "having", detail = "AR: having(...)", doc = "group(:s).having('count(*) > 1')" },
  { word = "joins", detail = "AR: joins(...)", doc = "joins(:posts)" },
  { word = "left_joins", detail = "AR: left_joins(...)", doc = "left_joins(:posts)" },
  { word = "includes", detail = "AR: includes(...)", doc = "includes(:posts)" },
  { word = "preload", detail = "AR: preload(...)", doc = "preload(:posts)" },
  { word = "eager_load", detail = "AR: eager_load(...)", doc = "eager_load(:posts)" },
  { word = "references", detail = "AR: references(...)", doc = "includes(:posts).references(:posts)" },
  { word = "find", detail = "AR: find(id)", doc = "find(params[:id])" },
  { word = "find_by", detail = "AR: find_by(...)", doc = "find_by(email: params[:email])" },
  { word = "find_or_create_by", detail = "AR: find_or_create_by", doc = "find_or_create_by(email: e)" },
  { word = "find_or_initialize_by", detail = "AR: find_or_initialize_by", doc = "find_or_initialize_by(email: e)" },
  { word = "first_or_create", detail = "AR: first_or_create", doc = "where(email: e).first_or_create" },
  { word = "pluck", detail = "AR: pluck(...)", doc = "pluck(:id, :email)" },
  { word = "pick", detail = "AR: pick(...)", doc = "pick(:email)" },
  { word = "ids", detail = "AR: ids", doc = "where(active: true).ids" },
  { word = "create", detail = "AR: create(...)", doc = "create(name: name)" },
  { word = "save", detail = "AR: save", doc = "save" },
  { word = "update", detail = "AR: update(...)", doc = "update(name: name)" },
  { word = "destroy", detail = "AR: destroy", doc = "destroy" },
  { word = "reload", detail = "AR: reload", doc = "reload" },
  -- ActiveRecord model macros
  { word = "alias_attribute", detail = "Rails: alias_attribute", doc = "alias_attribute :name, :full_name" },
  { word = "default_scope", detail = "Rails: default_scope", doc = "default_scope { order(created_at: :desc) }" },
  { word = "has_secure_password", detail = "Rails: has_secure_password", doc = "has_secure_password" },
  { word = "has_secure_token", detail = "Rails: has_secure_token", doc = "has_secure_token :auth_token" },
  { word = "has_one_attached", detail = "ActiveStorage", doc = "has_one_attached :avatar" },
  { word = "has_many_attached", detail = "ActiveStorage", doc = "has_many_attached :files" },
  { word = "has_rich_text", detail = "ActionText", doc = "has_rich_text :body" },
  { word = "normalizes", detail = "Rails 7.1: normalizes", doc = "normalizes :email, with: ->(e) { e.strip.downcase }" },
  { word = "encrypts", detail = "Rails 7: encrypts", doc = "encrypts :api_key" },
  { word = "transaction", detail = "AR: transaction", doc = "transaction do … end" },
  -- Controllers
  { word = "render", detail = "Controller: render", doc = "render :show  # or render json: @user" },
  { word = "redirect_to", detail = "Controller: redirect_to", doc = "redirect_to @post, notice: 'Saved'" },
  { word = "head", detail = "Controller: head", doc = "head :no_content" },
  { word = "params", detail = "Controller: params", doc = "params[:id] / params.require(:post).permit(:title)" },
  { word = "session", detail = "Controller: session", doc = "session[:user_id]" },
  { word = "cookies", detail = "Controller: cookies", doc = "cookies[:theme]" },
  { word = "flash", detail = "Controller: flash", doc = "flash[:notice] = 'Saved'" },
  { word = "request", detail = "Controller: request", doc = "request.remote_ip" },
  { word = "helper_method", detail = "Controller: helper_method", doc = "helper_method :current_user" },
  { word = "respond_to", detail = "Controller: respond_to", doc = "respond_to :html, :json" },
  { word = "protect_from_forgery", detail = "Controller", doc = "protect_from_forgery with: :exception" },
  { word = "skip_forgery_protection", detail = "Controller", doc = "skip_forgery_protection only: :webhook" },
  { word = "permit", detail = "Strong params: permit", doc = "params.require(:post).permit(:title, :body)" },
  -- Routes (config/routes.rb)
  { word = "resources", detail = "Routes: resources", doc = "resources :posts" },
  { word = "resource", detail = "Routes: resource", doc = "resource :profile, only: :show" },
  { word = "root", detail = "Routes: root", doc = 'root "posts#index"' },
  { word = "get", detail = "Routes: get", doc = 'get "search", to: "pages#search"' },
  { word = "post", detail = "Routes: post", doc = 'post "checkout", to: "orders#create"' },
  { word = "put", detail = "Routes: put", doc = 'put "avatar", to: "users#update"' },
  { word = "patch", detail = "Routes: patch", doc = 'patch "avatar", to: "users#update"' },
  { word = "delete", detail = "Routes: delete", doc = 'delete "logout", to: "sessions#destroy"' },
  { word = "namespace", detail = "Routes: namespace", doc = "namespace :admin do … end" },
  { word = "member", detail = "Routes: member", doc = "member { post :publish }" },
  { word = "collection", detail = "Routes: collection", doc = "collection { get :search }" },
  { word = "concern", detail = "Routes: concern", doc = "concern :commentable do … end" },
  { word = "concerns", detail = "Routes: concerns", doc = "resources :posts, concerns: :commentable" },
  { word = "mount", detail = "Routes: mount", doc = "mount Sidekiq::Web => '/sidekiq'" },
  -- Migrations (extra)
  { word = "change_column", detail = "Migration", doc = "change_column :posts, :title, :text" },
  { word = "rename_column", detail = "Migration", doc = "rename_column :posts, :name, :title" },
  { word = "rename_table", detail = "Migration", doc = "rename_table :posts, :articles" },
  { word = "remove_index", detail = "Migration", doc = "remove_index :posts, :slug" },
  { word = "remove_reference", detail = "Migration", doc = "remove_reference :posts, :user" },
  { word = "remove_foreign_key", detail = "Migration", doc = "remove_foreign_key :posts, :users" },
  { word = "add_timestamps", detail = "Migration", doc = "add_timestamps :posts" },
  { word = "remove_timestamps", detail = "Migration", doc = "remove_timestamps :posts" },
  { word = "reversible", detail = "Migration", doc = "reversible do |dir| … end" },
  { word = "enable_extension", detail = "Migration", doc = 'enable_extension "pgcrypto"' },
  { word = "create_join_table", detail = "Migration", doc = "create_join_table :posts, :tags" },
  { word = "drop_table", detail = "Migration", doc = "drop_table :posts" },
  { word = "change_column_null", detail = "Migration", doc = "change_column_null :posts, :title, false" },
  -- Jobs / Mailers
  { word = "queue_as", detail = "Job: queue_as", doc = "queue_as :default" },
  { word = "perform_later", detail = "Job: perform_later", doc = "MyJob.perform_later(arg)" },
  { word = "deliver_later", detail = "Mailer: deliver_later", doc = "UserMailer.welcome(u).deliver_later" },
  { word = "deliver_now", detail = "Mailer: deliver_now", doc = "UserMailer.welcome(u).deliver_now" },
  { word = "mail", detail = "Mailer: mail", doc = "mail to: user.email, subject: 'Hi'" },
  { word = "layout", detail = "Mailer: layout", doc = "layout 'mailer'" },
  -- RSpec
  { word = "describe", detail = "RSpec: describe", doc = "describe User do … end" },
  { word = "context", detail = "RSpec: context", doc = 'context "when invalid" do … end' },
  { word = "it", detail = "RSpec: it", doc = 'it "works" do … end' },
  { word = "expect", detail = "RSpec: expect", doc = "expect(user).to be_valid" },
  { word = "allow", detail = "RSpec: allow", doc = "allow(obj).to receive(:method)" },
  { word = "receive", detail = "RSpec: receive", doc = "expect(obj).to have_received(:method)" },
  { word = "before", detail = "RSpec: before", doc = "before { sign_in user }" },
  { word = "after", detail = "RSpec: after", doc = "after { cleanup }" },
  { word = "let", detail = "RSpec: let", doc = "let(:user) { create(:user) }" },
  { word = "subject", detail = "RSpec: subject", doc = "subject(:user) { create(:user) }" },
  { word = "shared_examples", detail = "RSpec", doc = 'shared_examples "auditable" do … end' },
  { word = "it_behaves_like", detail = "RSpec", doc = 'it_behaves_like "auditable"' },
  -- FactoryBot
  { word = "factory", detail = "FactoryBot", doc = "factory :user do … end" },
  { word = "trait", detail = "FactoryBot", doc = "trait :admin do … end" },
  { word = "sequence", detail = "FactoryBot", doc = "sequence(:email) { |n| \"u#{n}@x.com\" }" },
  { word = "association", detail = "FactoryBot", doc = "association :author" },
  -- Ruby extras
  { word = "class", detail = "Ruby: class", doc = "class User < ApplicationRecord … end" },
  { word = "module", detail = "Ruby: module", doc = "module Approvals … end" },
  { word = "raise", detail = "Ruby: raise", doc = 'raise "boom"' },
  { word = "yield", detail = "Ruby: yield", doc = "yield(arg) if block_given?" },
  { word = "super", detail = "Ruby: super", doc = "super" },
  { word = "lambda", detail = "Ruby: lambda", doc = "lambda { |x| x }" },
  { word = "proc", detail = "Ruby: proc", doc = "proc { |x| x }" },
  { word = "private_constant", detail = "Ruby", doc = "private_constant :SECRET" },
  { word = "module_function", detail = "Ruby", doc = "module_function :helper" },
}

-- Rails base classes: superclass references like `< ApplicationRecord`
-- never appear as project `class` defs, so complete them statically.
local RAILS_CONSTANTS = { "ApplicationRecord", "ApplicationController", "ApplicationJob", "ApplicationMailer", "ApplicationHelper" }
-- These are bare words before the colon, so they never come from the
-- `def`-scan above and ruby-lsp often misses them mid-line while typing.
local RAILS_OPTIONS = {
  -- Association options
  { word = "class_name", detail = "Rails opt: class_name:", doc = "belongs_to :author, class_name: 'User'" },
  { word = "foreign_key", detail = "Rails opt: foreign_key:", doc = "belongs_to :author, foreign_key: :user_id" },
  { word = "primary_key", detail = "Rails opt: primary_key:", doc = "has_many :posts, primary_key: :uuid" },
  { word = "dependent", detail = "Rails opt: dependent:", doc = "has_many :posts, dependent: :destroy" },
  { word = "through", detail = "Rails opt: through:", doc = "has_many :tags, through: :taggings" },
  { word = "source", detail = "Rails opt: source:", doc = "has_many :followers, through: :follows, source: :user" },
  { word = "source_type", detail = "Rails opt: source_type:", doc = "has_many :assets, through: :attachables, source_type: 'Image'" },
  { word = "optional", detail = "Rails opt: optional:", doc = "belongs_to :team, optional: true" },
  { word = "required", detail = "Rails opt: required:", doc = "belongs_to :team, required: true" },
  { word = "polymorphic", detail = "Rails opt: polymorphic:", doc = "belongs_to :attachable, polymorphic: true" },
  { word = "touch", detail = "Rails opt: touch:", doc = "belongs_to :post, touch: true" },
  { word = "counter_cache", detail = "Rails opt: counter_cache:", doc = "belongs_to :post, counter_cache: true" },
  { word = "inverse_of", detail = "Rails opt: inverse_of:", doc = "has_many :posts, inverse_of: :author" },
  { word = "autosave", detail = "Rails opt: autosave:", doc = "has_one :profile, autosave: true" },
  { word = "validate", detail = "Rails opt: validate:", doc = "has_many :posts, validate: false" },
  { word = "as", detail = "Rails opt: as:", doc = "has_many :pictures, as: :imageable" },
  -- Validation / common kwargs
  { word = "presence", detail = "Rails opt: presence:", doc = "validates :name, presence: true" },
  { word = "uniqueness", detail = "Rails opt: uniqueness:", doc = "validates :email, uniqueness: true" },
  { word = "inclusion", detail = "Rails opt: inclusion:", doc = "validates :role, inclusion: { in: %w[admin user] }" },
  { word = "exclusion", detail = "Rails opt: exclusion:", doc = "validates :subdomain, exclusion: { in: %w[www] }" },
  { word = "format", detail = "Rails opt: format:", doc = "validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }" },
  { word = "length", detail = "Rails opt: length:", doc = "validates :bio, length: { maximum: 500 }" },
  { word = "numericality", detail = "Rails opt: numericality:", doc = "validates :age, numericality: { greater_than: 0 }" },
  { word = "confirmation", detail = "Rails opt: confirmation:", doc = "validates :password, confirmation: true" },
  { word = "acceptance", detail = "Rails opt: acceptance:", doc = "validates :terms, acceptance: true" },
  { word = "allow_nil", detail = "Rails opt: allow_nil:", doc = "validates :nick, length: { is: 3 }, allow_nil: true" },
  { word = "allow_blank", detail = "Rails opt: allow_blank:", doc = "validates :bio, length: { maximum: 500 }, allow_blank: true" },
  { word = "on", detail = "Rails opt: on:", doc = "validate :check, on: :create" },
  { word = "if", detail = "Rails opt: if:", doc = "validates :code, presence: true, if: :active?" },
  { word = "unless", detail = "Rails opt: unless:", doc = "validates :code, presence: true, unless: :archived?" },
  { word = "message", detail = "Rails opt: message:", doc = "validates :email, presence: { message: 'required' }" },
  { word = "with", detail = "Rails opt: with:", doc = "validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }" },
  { word = "minimum", detail = "Rails opt: minimum:", doc = "validates :bio, length: { minimum: 10 }" },
  { word = "maximum", detail = "Rails opt: maximum:", doc = "validates :bio, length: { maximum: 500 }" },
  { word = "too_long", detail = "Rails opt: too_long:", doc = "validates :bio, length: { maximum: 500, too_long: 'too long' }" },
  { word = "too_short", detail = "Rails opt: too_short:", doc = "validates :pwd, length: { minimum: 8, too_short: 'too short' }" },
  { word = "greater_than", detail = "Rails opt: greater_than:", doc = "validates :age, numericality: { greater_than: 0 }" },
  { word = "less_than", detail = "Rails opt: less_than:", doc = "validates :age, numericality: { less_than: 150 }" },
  { word = "only_integer", detail = "Rails opt: only_integer:", doc = "validates :qty, numericality: { only_integer: true }" },
  { word = "only", detail = "Rails opt: only:", doc = "before_action :auth, only: :index" },
  { word = "except", detail = "Rails opt: except:", doc = "before_action :auth, except: :show" },
  { word = "to", detail = "Rails opt: to:", doc = "delegate :email, to: :user" },
  { word = "prefix", detail = "Rails opt: prefix:", doc = "delegate :email, to: :user, prefix: true" },
  { word = "coder", detail = "Rails opt: coder:", doc = "serialize :tags, coder: JSON" },
}

-- bufnr integers get reused after :wq + reopen; drop stale entries.
pcall(vim.api.nvim_create_autocmd, { "BufWipeout", "BufDelete" }, {
  group = vim.api.nvim_create_augroup("ConfigRubyDefsCache", { clear = true }),
  callback = function(e)
    buffer_cache[e.buf] = nil
  end,
})

local function scan_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  local ok_tick, tick = pcall(vim.api.nvim_buf_get_changedtick, buf)
  if not ok_tick then
    tick = vim.b[buf].changedtick
  end
  local buf_name = vim.api.nvim_buf_get_name(buf)
  local hit = buffer_cache[buf]
  -- Also validate buffer name: guards bufnr-reuse stale hits.
  if hit and hit.tick == tick and hit.name == buf_name then
    return hit.result
  end
  local ok_lines, lines = pcall(vim.api.nvim_buf_get_lines, buf, 0, -1, false)
  if not ok_lines then
    return nil
  end
  local ok, result = pcall(scan, table.concat(lines, "\n"))
  result = ok and result or nil
  buffer_cache[buf] = { tick = tick, name = buf_name, result = result }
  return result
end

local function buffer_def_names()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= "ruby" then
    return nil
  end
  local result = scan_buffer(buf)
  if not result then
    return nil
  end
  local names = {}
  for _, def in ipairs(result.defs or {}) do
    names[def.name] = true
  end
  for _, cls in ipairs(result.classes or {}) do
    names[cls.name] = true
  end
  return names, vim.fs.basename(vim.api.nvim_buf_get_name(buf))
end

function M.drop_lsp_duplicates(_, items)
  local names, file = buffer_def_names()
  if not names then
    return items
  end
  return vim.tbl_filter(function(item)
    local origin = item.labelDetails and item.labelDetails.description
    return not (names[item.label] and origin == file)
  end, items)
end

function M.drop_buffer_duplicates(_, items)
  -- Only dedup when our ruby_defs source can actually supply the item.
  -- If treesitter scan fails (parser missing / broken syntax right after
  -- typing), scan_buffer is nil and we must keep buffer words as fallback,
  -- otherwise the fresh func disappears from ALL sources.
  local names = buffer_def_names()
  if not names then
    return items
  end
  return vim.tbl_filter(function(item)
    return not names[item.label]
  end, items)
end

local function resolve(req, from_dir, root)
  local rel = req.path:match("%.rb$") and req.path or req.path .. ".rb"
  local candidates = req.kind == "require_relative" and { vim.fs.joinpath(from_dir, rel) }
    or { vim.fs.joinpath(root, "lib", rel), vim.fs.joinpath(root, rel), vim.fs.joinpath(from_dir, rel) }
  for _, path in ipairs(candidates) do
    path = vim.fs.normalize(path)
    if vim.uv.fs_stat(path) then
      return path
    end
  end
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:enabled()
  local ft = vim.bo.filetype
  return ok_query and (ft == "ruby" or ft == "eruby")
end

function M:get_completions(ctx, callback)
  local done = function(items)
    local ok_cb = pcall(callback, {
      items = items or {},
      is_incomplete_forward = false,
      is_incomplete_backward = false,
    })
    if not ok_cb then
      pcall(callback, { items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    end
  end
  local ok = pcall(function()
    local before = ctx.line:sub(1, ctx.bounds.start_col - 1)
    -- Single `:` starts a symbol (`:process`) and `.` a method call:
    -- our bare-word DSL doesn't apply there, let LSP/buffer handle it.
    -- But `::` is a namespace (`Approvals::Process`), where constant
    -- completion DOES apply, so only bail on a lone trailing colon.
    local namespaced = before:match("::$") ~= nil
    if not namespaced and before:match("[%.:]$") then
      done({})
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    local dir = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
    local root = vim.fs.root(buf, { ".git", "Gemfile" }) or dir

    local items, seen_names, visited = {}, {}, { [vim.fs.normalize(name)] = true }
    local function collect(result, file_dir, origin)
      if not result then
        return
      end
      for _, def in ipairs(result.defs or {}) do
        if (def.top or not origin) and def.name and not seen_names[def.name] then
          seen_names[def.name] = true
          items[#items + 1] = {
            label = def.name,
            kind = def.top and vim.lsp.protocol.CompletionItemKind.Function or vim.lsp.protocol.CompletionItemKind.Method,
            detail = "def " .. def.name .. (def.params or ""),
            labelDetails = origin and { description = origin } or nil,
            insertText = def.name,
            insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
          }
        end
      end
      for _, cls in ipairs(result.classes or {}) do
        -- Model / constant names: completes `class_name: 'User'`
        -- string values as well as bare `User.new` references.
        if cls.name and not seen_names[cls.name] then
          seen_names[cls.name] = true
          items[#items + 1] = {
            label = cls.name,
            kind = vim.lsp.protocol.CompletionItemKind.Class,
            detail = origin and ("class " .. cls.name .. " (" .. origin .. ")") or ("class " .. cls.name),
            labelDetails = origin and { description = origin } or nil,
            insertText = cls.name,
            insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
          }
        end
      end
      for _, req in ipairs(result.requires or {}) do
        local path = req.path and resolve(req, file_dir, root)
        if path and not visited[path] then
          visited[path] = true
          local sub = scan_file(path)
          if sub then
            collect(sub, vim.fs.dirname(path), vim.fs.basename(path))
          end
        end
      end
    end

    local result = scan_buffer(buf)
    if result then
      collect(result, dir, nil)
    end
    -- Always offer Rails/Ruby DSL keywords (belongs_to, validates, …).
    -- Blink fuzzy-filters by what you typed, so returning the full list
    -- is cheap and keeps them visible even while ruby-lsp is indexing.
    -- After `::` only constants apply, so skip bare-word DSL there.
    local Keyword = vim.lsp.protocol.CompletionItemKind.Keyword
    local Class = vim.lsp.protocol.CompletionItemKind.Class
    if not namespaced then
    for _, dsl in ipairs(RAILS_DSL) do
      if not seen_names[dsl.word] then
        seen_names[dsl.word] = true
        items[#items + 1] = {
          label = dsl.word,
          kind = Keyword,
          detail = dsl.detail,
          documentation = dsl.doc,
          insertText = dsl.word,
          insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
        }
      end
    end
    for _, opt in ipairs(RAILS_OPTIONS) do
      -- Option keys always take `key: value`, so accepting the item
      -- inserts the trailing colon + space, ready for the value.
      if not seen_names[opt.word] then
        seen_names[opt.word] = true
        items[#items + 1] = {
          label = opt.word,
          kind = Keyword,
          detail = opt.detail,
          documentation = opt.doc,
          insertText = opt.word .. ": ",
          insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
        }
      end
    end
    end
    for _, const in ipairs(RAILS_CONSTANTS) do
      -- `class ApproverSet < ApplicationRecord`: base classes never
      -- appear as project defs, and apply after `::` too.
      if not seen_names[const] then
        seen_names[const] = true
        items[#items + 1] = {
          label = const,
          kind = Class,
          detail = "Rails base class",
          insertText = const,
          insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
        }
      end
    end
    done(items)
  end)
  if not ok then
    done({})
  end
end

return M
