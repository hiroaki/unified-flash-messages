module ApplicationHelper
  # Centralised definitions for flash templates. Keep colors and border
  # classes in one place so UI elements can reuse the same palette.
  def flash_template_definitions
    [
      {
        id: "alert",
        text_color: "text-red-700",
        bg_color: "bg-red-100",
        border_class: "border-red-500"
      },
      {
        id: "notice",
        text_color: "text-blue-700",
        bg_color: "bg-blue-100",
        border_class: "border-blue-500"
      },
      {
        id: "warning",
        text_color: "text-yellow-700",
        bg_color: "bg-yellow-100",
        border_class: "border-yellow-500"
      }
    ]
  end

  # Return a Tailwind border class corresponding to a flash type.
  # Keeps form border colors consistent with flash templates.
  def flash_border_class_for(type)
    tpl = flash_template_definitions.find { |t| t[:id] == type.to_s }
    tpl ? tpl[:border_class] : "border-gray-300"
  end

  # Render a compact filter control (label + input) used on the memos index.
  # - `form` is the form builder
  # - `field` is a symbol (:offset, :limit, :sort_order)
  # - `label_text` is the visible label
  # - `select_options` (optional) for select field ([[label, value], ...])
  # - `default` is the default input value
  # - `number_min` (optional) min attribute for number inputs
  # - `param_error` and `param_warning` are booleans; the caller should
  #   perform any matching of instance variables to fields.
  def filter_control(form, field, label_text:, select_options: nil, default: nil, number_min: nil, param_error: nil, param_warning: nil)
    div_class = "flex items-center space-x-2"

    base_input_class = "rounded-md border px-2 py-1"
    base_input_class += " w-24" if select_options.nil? # give width to number inputs

    border_class = if param_error
      flash_border_class_for(:alert)
    elsif param_warning
      flash_border_class_for(:warning)
    else
      nil
    end

    input_class = [ base_input_class, border_class ].compact.join(" ")

    content_tag(:div, class: div_class) do
      label_html = form.label(field, label_text, class: "text-sm")

      input_html = if select_options
        form.select(field, options_for_select(select_options, default), { include_blank: false }, { id: field.to_s, class: input_class })
      else
        opts = { id: field.to_s, class: input_class }
        opts[:min] = number_min unless number_min.nil?
        form.number_field(field, { value: default }.merge(opts))
      end

      safe_join([ label_html, input_html ], "\n")
    end
  end
end
