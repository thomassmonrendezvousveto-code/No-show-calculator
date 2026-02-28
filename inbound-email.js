// api/inbound-email.js
// Reçoit les emails de Sendgrid Inbound Parse et crée des tickets Supabase

import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).end();

  try {
    // Sendgrid envoie les données en multipart/form-data
    const from     = req.body.from     || "";
    const subject  = req.body.subject  || "(sans objet)";
    const text     = req.body.text     || req.body.html || "";

    // Extraire l'adresse email de l'expéditeur
    // "Dr. Dupont <dupont@clinique.fr>" → "dupont@clinique.fr"
    const emailMatch = from.match(/<(.+?)>/) || from.match(/([^\s]+@[^\s]+)/);
    const senderEmail = emailMatch ? emailMatch[1].toLowerCase().trim() : from.toLowerCase().trim();

    // Chercher si cet email correspond à une clinique connue
    const { data: clinic } = await supabase
      .from("clinics")
      .select("id, name, city")
      .ilike("email", senderEmail)
      .maybeSingle();

    // Nettoyer le texte du message (enlever les signatures et forwards)
    const cleanText = text
      .replace(/\r\n/g, "\n")
      .split(/^(--|__|\s*De\s*:|\s*From\s*:)/m)[0]
      .trim()
      .slice(0, 2000);

    // Créer le ticket
    const { data: ticket, error } = await supabase
      .from("tickets")
      .insert({
        clinic_id:    clinic?.id || null,
        title:        subject.replace(/^(Re:|Fwd:|Tr:)\s*/i, "").trim(),
        status:       "Ouvert",
        priority:     "Normale",
        channel:      "Email",
        sender_email: senderEmail,
        sender_name:  from.replace(/<.*>/, "").trim() || senderEmail,
      })
      .select()
      .single();

    if (error) throw error;

    // Ajouter le corps de l'email comme premier message
    if (cleanText) {
      await supabase.from("messages").insert({
        ticket_id: ticket.id,
        from_name: ticket.sender_name,
        text:      cleanText,
        kind:      "client",
      });
    }

    console.log(`✅ Ticket créé: ${ticket.id} | Clinique: ${clinic?.name || "inconnue"} | De: ${senderEmail}`);
    return res.status(200).json({ ok: true, ticketId: ticket.id });

  } catch (err) {
    console.error("❌ Erreur inbound-email:", err);
    return res.status(500).json({ error: err.message });
  }
}

export const config = {
  api: { bodyParser: { sizeLimit: "5mb" } },
};
