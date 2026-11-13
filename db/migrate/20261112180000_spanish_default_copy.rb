class SpanishDefaultCopy < ActiveRecord::Migration[8.1]
  def up
    change_column_default :weddings, :headline, from: "Together is a beautiful place to be.", to: "Juntos es un lugar hermoso."

    Wedding.where(headline: "Together is a beautiful place to be.").update_all(headline: "Juntos es un lugar hermoso.")
    Wedding.where(headline: "The beginning of our forever.").update_all(headline: "El comienzo de nuestro siempre.")
    Wedding.where(headline: "Our next great adventure.").update_all(headline: "Nuestra siguiente gran aventura.")
    Wedding.where("invitation_text LIKE ?", "With full hearts and the biggest smiles%").update_all(
      invitation_text: "Con el corazón lleno y una sonrisa enorme, te invitamos a celebrar nuestra boda. Acompáñanos en un día de amor, risas y un poco de baile bajo las estrellas. Nuestro día favorito no estaría completo sin las personas que más queremos.",
      story: "Lo que empezó con un simple hola se volvió nuestra aventura favorita. Entre cafés, caminatas largas y todos los momentos pequeños, encontramos un hogar el uno en el otro.\n\nAhora estamos listos para el siguiente capítulo, y queremos empezarlo rodeados de las personas que amamos.",
      dress_code: "Formal de jardín · Un poco de color es bienvenido."
    )
    Wedding.where("invitation_text LIKE ?", "A beautiful day is on its way%").update_all(
      invitation_text: "Se acerca un día hermoso. Nos hace mucha ilusión celebrarlo contigo."
    )
    Wedding.where("invitation_text LIKE ?", "Join us for a day filled with love%").update_all(
      invitation_text: "Acompáñanos en un día lleno de amor, risas y todas las personas que queremos."
    )
    Event.where(title: "The ceremony").where("notes LIKE ?", "Please arrive 15 minutes early%").update_all(
      title: "La ceremonia",
      notes: "Llega 15 minutos antes para encontrar tu lugar."
    )
    Event.where(title: "Dinner & dancing").where("notes LIKE ?", "A toast to love%").update_all(
      title: "Cena y baile",
      notes: "Un brindis, una cena bonita y una pista de baile que te espera."
    )
  end

  def down
    change_column_default :weddings, :headline, from: "Juntos es un lugar hermoso.", to: "Together is a beautiful place to be."
  end
end
