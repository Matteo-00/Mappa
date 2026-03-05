import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../pages/event_detail_page.dart';

/// Widget per visualizzare la timeline degli eventi con stati automatici
/// Linea verticale del tempo a sinistra, eventi ordinati per orario
class EventTimeline extends StatelessWidget {
  final List<EventModel> events;

  const EventTimeline({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final status = event.getStatus();
        
        return _buildTimelineItem(
          context: context,
          event: event,
          status: status,
          isLast: index == events.length - 1,
        );
      },
    );
  }

  /// Costruisce un singolo item della timeline
  Widget _buildTimelineItem({
    required BuildContext context,
    required EventModel event,
    required EventStatus status,
    required bool isLast,
  }) {
    // Colori in base allo stato
    Color cardColor;
    Color textColor;
    Color timeColor;
    bool showCurrentTag = false;
    double opacity = 1.0;
    Color? borderColor;

    switch (status) {
      case EventStatus.past:
        // Evento passato: card oscurata, testo grigio
        cardColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF9E9E9E);
        timeColor = const Color(0xFFBDBDBD);
        opacity = 0.6;
        break;
      case EventStatus.current:
        // Evento in corso: bordo rosso, card bianca
        cardColor = Colors.white;
        textColor = Colors.black87;
        timeColor = const Color(0xFF2F80ED); // Blu per orario
        showCurrentTag = true;
        borderColor = const Color(0xFFB22222); // Bordo rosso
        break;
      case EventStatus.upcoming:
        // Evento futuro: card bianca normale
        cardColor = Colors.white;
        textColor = Colors.black87;
        timeColor = const Color(0xFF2F80ED); // Blu per orario
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linea verticale del tempo + pallino
          Column(
            children: [
              // Pallino
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: status == EventStatus.current
                      ? const Color(0xFFB22222)
                      : (status == EventStatus.past
                          ? const Color(0xFFBDBDBD)
                          : const Color(0xFFB22222)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
              // Linea verticale (se non è l'ultimo)
              if (!isLast)
                Container(
                  width: 2,
                  height: 100,
                  color: const Color(0xFFEAEAEA),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Card evento
          Expanded(
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor ?? const Color(0xFFEAEAEA),
                    width: borderColor != null ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Orario + Tag "IN CORSO"
                    Row(
                      children: [
                        Text(
                          event.time,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: timeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (showCurrentTag) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB22222),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'IN CORSO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Titolo evento
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: status == EventStatus.past
                              ? const Color(0xFFBDBDBD)
                              : const Color(0xFF6B6B6B),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Pulsante "Vai ai dettagli"
                    if (status != EventStatus.past)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailPage(event: event),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2F80ED),
                            side: const BorderSide(
                              color: Color(0xFF2F80ED),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Vai ai dettagli',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
