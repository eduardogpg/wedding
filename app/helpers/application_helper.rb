module ApplicationHelper
  def icon(name, size: 20)
    paths = {
      "grid" => '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
      "heart" => '<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z"/>',
      "globe" => '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c5 5 5 13 0 18-5-5-5-13 0-18Z"/>',
      "edit" => '<path d="m16 3 5 5-12 12-6 1 1-6L16 3ZM13 6l5 5"/>',
      "plus" => '<path d="M12 5v14M5 12h14"/>',
      "arrow" => '<path d="M5 12h14m-5-5 5 5-5 5"/>',
      "external" => '<path d="M14 3h7v7m0-7L10 14M10 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-5"/>',
      "calendar" => '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 11h18m-12 4h2m3 0h2"/>',
      "users" => '<circle cx="9" cy="7" r="4"/><path d="M2 21v-3a7 7 0 0 1 14 0v3M17 4a4 4 0 0 1 0 8m1 3a5 5 0 0 1 4 5"/>',
      "pin" => '<path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="2.5"/>',
      "search" => '<circle cx="10.5" cy="10.5" r="7"/><path d="m16 16 5 5"/>',
      "logout" => '<path d="M9 3H4v18h5m5-15 6 6-6 6m-7-6h13"/>',
      "check" => '<path d="m5 12 4 4L19 6"/>',
      "image" => '<rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8" cy="8" r="1.5"/><path d="m21 15-5-5L4 21"/>',
      "download" => '<path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5"/>',
      "copy" => '<rect x="8" y="8" width="13" height="13" rx="2"/><path d="M16 8V3H3v13h5"/>',
      "clock" => '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'
    }
    content_tag(:svg, paths.fetch(name, paths["heart"]).html_safe,
      width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
      "stroke-width": 1.6, "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true)
  end
end
