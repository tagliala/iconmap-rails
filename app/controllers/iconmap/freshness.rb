module Iconmap::Freshness
  def stale_when_iconmap_changes
    etag { Rails.application.iconmap.digest(resolver: helpers) if request.format&.html? }
  end
end
