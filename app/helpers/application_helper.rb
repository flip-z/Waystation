module ApplicationHelper
  def render_markdown(text)
    safe_text = text.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    Commonmarker.to_html(
      safe_text,
      options: {
        render: { unsafe: false },
        extension: { table: true, strikethrough: true, autolink: true }
      }
    )
  end
end
