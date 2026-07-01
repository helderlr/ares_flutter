import 'package:flutter/material.dart';



import '../../agendamento/models/agendamento_model.dart';



class AgendaCirurgiaReportItemTile extends StatelessWidget {

  final AgendaCirurgia item;



  const AgendaCirurgiaReportItemTile({

    super.key,

    required this.item,

  });



  static const double _matcirIndent = 110;



  @override

  Widget build(BuildContext context) {

    final bool isCancelada = item.isAgendaCancelada;

    final List<String> materialLines = item.matcirReportLines;

    return Container(

      decoration: BoxDecoration(

        color: isCancelada ? Colors.grey.shade200 : null,

        border: Border(

          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),

        ),

      ),

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: <Widget>[

          SingleChildScrollView(

            scrollDirection: Axis.horizontal,

            child: Row(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: <Widget>[

                _cell('${item.nummov}', 52),

                _cell(item.horcir ?? '', 58),

                _cell(item.nomcli ?? '', 120),

                _cell(item.nommed ?? '', 120),

                _cell(item.nomconv ?? '', 90),

                _cell(item.tipoCirurgiaDisplay, 100),

                _cell(item.nompac ?? '', 120),

                _cell(item.nomven ?? '', 140),

                _cell(item.tipmarDisplay, 28),

                _cell(item.situacDisplay, 24),

                _staCell(

                  isCancelada: isCancelada,

                  status: item.statusAgendaDisplay,

                ),

              ],

            ),

          ),

          if (materialLines.isNotEmpty)

            Padding(

              padding: const EdgeInsets.only(

                left: _matcirIndent,

                top: 4,

                bottom: 2,

                right: 4,

              ),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: materialLines

                    .map(

                      (String line) => Text(

                        line,

                        style: TextStyle(

                          fontSize: 10,

                          color: Colors.grey.shade800,

                          height: 1.35,

                        ),

                      ),

                    )

                    .toList(),

              ),

            ),

        ],

      ),

    );

  }



  Widget _staCell({

    required bool isCancelada,

    required String status,

  }) {

    return SizedBox(

      width: 24,

      child: isCancelada

          ? Container(

              width: 8,

              height: 8,

              margin: const EdgeInsets.only(top: 4),

              decoration: const BoxDecoration(

                color: Colors.red,

                shape: BoxShape.circle,

              ),

            )

          : Text(

              status,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(fontSize: 10),

            ),

    );

  }



  Widget _cell(String text, double width) {

    return SizedBox(

      width: width,

      child: Text(

        text,

        maxLines: 1,

        overflow: TextOverflow.ellipsis,

        style: const TextStyle(fontSize: 10),

      ),

    );

  }

}



class AgendaCirurgiaReportHeaderRow extends StatelessWidget {

  const AgendaCirurgiaReportHeaderRow({super.key});



  @override

  Widget build(BuildContext context) {

    return Container(

      decoration: BoxDecoration(

        border: Border(

          bottom: BorderSide(color: Colors.grey.shade500, width: 0.8),

        ),

      ),

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

      child: const SingleChildScrollView(

        scrollDirection: Axis.horizontal,

        child: Row(

          children: <Widget>[

            _HeaderCell('Nummov', 52),

            _HeaderCell('HorCir', 58),

            _HeaderCell('Local Cirurgia', 120),

            _HeaderCell('Medico', 120),

            _HeaderCell('Convenio', 90),

            _HeaderCell('Tipo Cirurgia', 100),

            _HeaderCell('Paciente', 120),

            _HeaderCell('Vendedor', 140),

            _HeaderCell('Tipo', 28),

            _HeaderCell('Sit', 24),

            _HeaderCell('Sta', 24),

          ],

        ),

      ),

    );

  }

}



class _HeaderCell extends StatelessWidget {

  final String label;

  final double width;



  const _HeaderCell(this.label, this.width);



  @override

  Widget build(BuildContext context) {

    return SizedBox(

      width: width,

      child: Text(

        label,

        style: const TextStyle(

          fontSize: 10,

          fontWeight: FontWeight.bold,

        ),

      ),

    );

  }

}


