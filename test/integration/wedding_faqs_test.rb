require "test_helper"

class WeddingFaqsTest < ActionDispatch::IntegrationTest
  test "FAQs are optional and blank rows are ignored" do
    sign_in
    assert_no_difference "WeddingFaq.count" do
      post weddings_path, params: { wedding: wedding_attributes(faqs_attributes: {
        "0" => { question: " ", answer: "", visible: "1" }
      }) }
    end
    wedding = Wedding.last
    assert_redirected_to wedding_path(wedding)
    get preview_wedding_path(wedding)
    assert_response :success
    assert_select "#preguntas", count: 0
    assert_select "a[href='#preguntas']", count: 0
  end

  test "planner can add edit hide show and delete questions" do
    sign_in
    wedding = create_wedding(status: :published)
    patch wedding_path(wedding), params: { wedding: { faqs_attributes: {
      "0" => { question: "¿Hay estacionamiento?", answer: "Sí, dentro del lugar.", visible: "1" },
      "1" => { question: "Pregunta privada", answer: "No publicar todavía", visible: "0" }
    } } }
    assert_redirected_to wedding_path(wedding)
    assert_equal 2, wedding.faqs.count
    faq = wedding.faqs.first
    Wedding::PAGE_TEMPLATES.each_key do |template|
      wedding.update!(page_template: template)
      get preview_wedding_path(wedding)
      assert_response :success
      assert_select ".guest-faq summary", text: "¿Hay estacionamiento?", count: 1
      assert_select ".guest-faq", count: 1
      assert_not_includes response.body, "No publicar todavía"
    end
    host! "#{wedding.subdomain}.localhost"
    get "/"
    assert_select "#preguntas .guest-faq", count: 1
    assert_select "a[href='#preguntas']"
    host! "app.localhost"
    patch wedding_path(wedding), params: { wedding: { faqs_attributes: {
      "0" => { id: faq.id, question: "¿Dónde estacionarse?", visible: "0" }
    } } }
    assert_redirected_to wedding_path(wedding)
    assert_equal "¿Dónde estacionarse?", faq.reload.question
    get preview_wedding_path(wedding)
    assert_select "#preguntas", count: 0
    patch wedding_path(wedding), params: { wedding: { faqs_attributes: { "0" => { id: faq.id, visible: "1" } } } }
    assert faq.reload.visible?
    patch wedding_path(wedding), params: { wedding: { faqs_attributes: { "0" => { id: faq.id, _destroy: "1" } } } }
    assert_redirected_to wedding_path(wedding)
    assert_not WeddingFaq.exists?(faq.id)
  end

  test "incomplete questions explain the missing answer without saving" do
    sign_in
    wedding = create_wedding
    patch wedding_path(wedding), params: { wedding: { faqs_attributes: { "0" => { question: "¿Habrá transporte?", answer: "" } } } }
    assert_response :unprocessable_entity
    assert_select ".error-summary"
    assert_select "input[value='¿Habrá transporte?']"
    assert_empty wedding.faqs.reload
  end

  test "FAQ content is escaped and another wedding cannot edit it" do
    sign_in
    wedding = create_wedding
    faq = wedding.faqs.create!(question: "<script>alert(1)</script>", answer: "<img src=x onerror=alert(1)>\nUna respuesta.")
    get preview_wedding_path(wedding)
    assert_response :success
    assert_select ".guest-faq script, .guest-faq img", count: 0
    assert_select ".guest-faq", /Una respuesta/
    other = create_wedding(subdomain: "otra-boda")
    patch wedding_path(other), params: { wedding: { faqs_attributes: { "0" => { id: faq.id, answer: "Cambio ajeno" } } } }
    assert_response :not_found
    assert_not_equal "Cambio ajeno", faq.reload.answer
    wedding.destroy!
    assert_not WeddingFaq.exists?(faq.id)
  end
end
