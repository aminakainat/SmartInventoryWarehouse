import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_inventory/core/theme.dart';

class CustomLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final String title;
  final Color lineColor;

  const CustomLineChart({
    super.key,
    required this.data,
    required this.labels,
    this.title = "Sales Over Time",
    this.lineColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final labelStyle = TextStyle(
      color: isDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: LineChartPainter(
                  data: data,
                  labels: labels,
                  lineColor: lineColor,
                  gridColor: gridColor,
                  labelStyle: labelStyle,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;

  LineChartPainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double paddingX = 40.0;
    final double paddingY = 20.0;
    final double chartWidth = size.width - paddingX - 10;
    final double chartHeight = size.height - paddingY - 20;

    final double maxVal = data.reduce(max);
    final double minVal = 0.0;
    final double range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 4; i++) {
      final double y = paddingY + chartHeight - (chartHeight / 4 * i);
      canvas.drawLine(
        Offset(paddingX, y),
        Offset(size.width - 10, y),
        gridPaint,
      );

      final double val = minVal + (range / 4 * i);
      String textVal = val >= 1000
          ? "\$${(val / 1000).toStringAsFixed(1)}k"
          : "\$${val.toStringAsFixed(0)}";
      if (val == 0) textVal = "\$0";

      textPainter.text = TextSpan(text: textVal, style: labelStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }
    final List<Offset> points = [];
    final double segmentWidth = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double x = paddingX + (i * segmentWidth);
      final double y =
          paddingY + chartHeight - (((data[i] - minVal) / range) * chartHeight);
      points.add(Offset(x, y));

      textPainter.text = TextSpan(text: labels[i], style: labelStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 15),
      );
    }
    if (points.isNotEmpty) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, paddingY + chartHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
        final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
        fillPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p2.dx,
          p2.dy,
        );
      }

      fillPath.lineTo(points.last.dx, paddingY + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [lineColor.withOpacity(0.35), lineColor.withOpacity(0.0)],
            ).createShader(
              Rect.fromLTWH(paddingX, paddingY, chartWidth, chartHeight),
            )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final strokePath = Path();
    strokePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      strokePath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    canvas.drawPath(strokePath, strokePaint);

    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var point in points) {
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(point, 5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}

class CustomBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String title;
  final Color barColor;

  const CustomBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.title = "Stock by Warehouse",
    this.barColor = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final labelStyle = TextStyle(
      color: isDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: BarChartPainter(
                  values: values,
                  labels: labels,
                  barColor: barColor,
                  gridColor: gridColor,
                  labelStyle: labelStyle,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color barColor;
  final Color gridColor;
  final TextStyle labelStyle;

  BarChartPainter({
    required this.values,
    required this.labels,
    required this.barColor,
    required this.gridColor,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double paddingX = 40.0;
    final double paddingY = 20.0;
    final double chartWidth = size.width - paddingX - 10;
    final double chartHeight = size.height - paddingY - 20;

    final double maxVal = values.reduce(max);
    final double minVal = 0.0;
    final double range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 4; i++) {
      final double y = paddingY + chartHeight - (chartHeight / 4 * i);
      canvas.drawLine(
        Offset(paddingX, y),
        Offset(size.width - 10, y),
        gridPaint,
      );

      final double val = minVal + (range / 4 * i);
      String textVal = val.toStringAsFixed(0);

      textPainter.text = TextSpan(text: textVal, style: labelStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    final double barSpacing = chartWidth / values.length;
    final double barWidth = barSpacing * 0.55;

    for (int i = 0; i < values.length; i++) {
      final double left =
          paddingX + (i * barSpacing) + (barSpacing - barWidth) / 2;
      final double height = (values[i] / range) * chartHeight;
      final double top = paddingY + chartHeight - height;
      final double right = left + barWidth;
      final double bottom = paddingY + chartHeight;

      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      final RRect rrect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, top, right, bottom),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );

      canvas.drawRRect(rrect, barPaint);

      textPainter.text = TextSpan(text: labels[i], style: labelStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + (barWidth - textPainter.width) / 2, size.height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) => true;
}

class CustomDonutChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final List<Color> colors;
  final String title;

  const CustomDonutChart({
    super.key,
    required this.values,
    required this.labels,
    required this.colors,
    this.title = "Category Breakdown",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = values.fold(0.0, (sum, val) => sum + val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                          painter: DonutChartPainter(
                            values: values,
                            colors: colors,
                            backgroundColor: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: labels.length,
                  itemBuilder: (context, i) {
                    final percentage = total > 0
                        ? (values[i] / total * 100).toStringAsFixed(1)
                        : "0";
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "$percentage%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color backgroundColor;

  DonutChartPainter({
    required this.values,
    required this.colors,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double total = values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) return;

    final double radius = size.width * 0.4;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.35
      ..strokeCap = StrokeCap.square;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
    final innerPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - (radius * 0.35 / 2) - 0.5, innerPaint);
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}
