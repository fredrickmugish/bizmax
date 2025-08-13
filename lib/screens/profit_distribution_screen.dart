import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profit_distribution.dart';
import '../models/business_metrics.dart';
import '../providers/business_provider.dart';
import '../services/profit_distribution_service.dart';
import '../utils/currency_formatter.dart';
import 'package:flutter/foundation.dart';

class ProfitDistributionScreen extends StatefulWidget {
  const ProfitDistributionScreen({super.key});

  @override
  State<ProfitDistributionScreen> createState() => _ProfitDistributionScreenState();
}

class _ProfitDistributionScreenState extends State<ProfitDistributionScreen> {
  final ProfitDistributionService _service = ProfitDistributionService.instance;
  ProfitDistribution? _distribution;
  bool _isCustomizing = false;
  
  // Custom distribution percentages (reinvestment has minimum 20%)
  double _customReinvestment = 20.0; // Starts at minimum 20%
  double _customBusinessSavings = 35.0;
  double _customBusinessExpenses = 25.0;
  double _customPersonalExpenses = 20.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDistribution();
    });
  }

  void _initializeDistribution() {
    final provider = context.read<BusinessProvider>();
    _distribution = _service.calculateRecommendedDistribution(provider.metrics);
    
    // Initialize custom values with recommended values
    if (_distribution != null) {
      _customReinvestment = _distribution!.reinvestmentPercentage;
      _customBusinessSavings = _distribution!.businessSavingsPercentage;
      _customBusinessExpenses = _distribution!.businessExpensesPercentage;
      _customPersonalExpenses = _distribution!.personalExpensesPercentage;
    }
    
    setState(() {});
  }

  void _updateCustomDistribution() {
    if (_distribution == null) return;
    
    final netProfit = _distribution!.totalProfit;
    _distribution = ProfitDistribution.custom(
      totalProfit: netProfit,
      reinvestmentPercentage: _customReinvestment,
      businessSavingsPercentage: _customBusinessSavings,
      businessExpensesPercentage: _customBusinessExpenses,
      personalExpensesPercentage: _customPersonalExpenses,
    );
    setState(() {});
  }

  List<String> _getDistributionWarnings() {
    return _service.getDistributionWarnings(
      reinvestmentPercentage: _customReinvestment,
      businessSavingsPercentage: _customBusinessSavings,
      businessExpensesPercentage: _customBusinessExpenses,
      personalExpensesPercentage: _customPersonalExpenses,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ugawaji wa Faida'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || _distribution == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfitHeader(provider.metrics),
                const SizedBox(height: 24),
                _buildDistributionChart(),
                const SizedBox(height: 24),
                _buildDistributionDetails(),
                const SizedBox(height: 24),
                _buildCustomizationSection(),
                const SizedBox(height: 24),
                _buildRecommendations(provider.metrics),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfitHeader(BusinessMetrics metrics) {
    final netProfit = metrics.totalNetProfit;
    final isPositive = netProfit > 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faida baada ya Matumizi',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(netProfit),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isPositive) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${ProfitDistribution.minimumReinvestmentPercentage}% ya faida lazima itumike kwa mtaji wa maendeleo kulingana na Sheria ya Biashara. Unaweza kuongeza zaidi kulingana na mahitaji ya biashara.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ugawaji wa faida unaofuata miongozo ya kitaalamu kwa ukuaji wa biashara',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              Text(
                'Hakuna faida ya sasa. Fokus kwenye kuongeza mauzo na kupunguza matumizi.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart() {
    if (_distribution?.totalProfit == null || _distribution!.totalProfit <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ugawaji wa Faida',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: ((_distribution?.reinvestmentPercentage ?? 0) * 10).round(),
                    child: _buildChartSegment(
                      'Mtaji wa Maendeleo',
                      Colors.green,
                      _distribution?.reinvestmentAmount ?? 0,
                      _distribution?.reinvestmentPercentage ?? 0,
                    ),
                  ),
                  Expanded(
                    flex: ((_distribution?.businessSavingsPercentage ?? 0) * 10).round(),
                    child: _buildChartSegment(
                      'Akiba ya Biashara',
                      Colors.blue,
                      _distribution?.businessSavingsAmount ?? 0,
                      _distribution?.businessSavingsPercentage ?? 0,
                    ),
                  ),
                  Expanded(
                    flex: ((_distribution?.businessExpensesPercentage ?? 0) * 10).round(),
                    child: _buildChartSegment(
                      'Matumizi ya Biashara',
                      Colors.orange,
                      _distribution?.businessExpensesAmount ?? 0,
                      _distribution?.businessExpensesPercentage ?? 0,
                    ),
                  ),
                  Expanded(
                    flex: ((_distribution?.personalExpensesPercentage ?? 0) * 10).round(),
                    child: _buildChartSegment(
                      'Matumizi Binafsi',
                      Colors.purple,
                      _distribution?.personalExpensesAmount ?? 0,
                      _distribution?.personalExpensesPercentage ?? 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSegment(String title, Color color, double amount, double percentage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionDetails() {
    if (_distribution == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maelezo ya Ugawaji',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDistributionItem(
              'Mtaji wa Maendeleo',
              'Kununua bidhaa zaidi, kuboresha huduma, kufungua tawi',
              Colors.green,
              _distribution!.reinvestmentAmount,
              _distribution!.reinvestmentPercentage,
            ),
            _buildDistributionItem(
              'Akiba ya Biashara',
              'Emergency fund, kukabiliana na hasara',
              Colors.blue,
              _distribution!.businessSavingsAmount,
              _distribution!.businessSavingsPercentage,
            ),
            _buildDistributionItem(
              'Matumizi ya Biashara',
              'Kodi, mishahara, umeme, na matumizi zingine',
              Colors.orange,
              _distribution!.businessExpensesAmount,
              _distribution!.businessExpensesPercentage,
            ),
            _buildDistributionItem(
              'Matumizi Binafsi',
              'Matumizi ya mmiliki wa biashara na familia',
              Colors.purple,
              _distribution!.personalExpensesAmount,
              _distribution!.personalExpensesPercentage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionItem(String title, String description, Color color, double amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                    fontSize: 13,
                ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  textAlign: TextAlign.right,
              ),
              Text(
                CurrencyFormatter.format(amount),
                style: TextStyle(
                  color: Colors.grey[600],
                    fontSize: 12,
                ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  textAlign: TextAlign.right,
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationSection() {
    final warnings = _getDistributionWarnings();
    // Calculate total of all categories (must be exactly 100%)
    final totalPercentage = _customReinvestment + _customBusinessSavings + _customBusinessExpenses + _customPersonalExpenses;
    final isValid = (totalPercentage - 100).abs() <= 0.01; // Very strict tolerance

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Ukurasa wa Ugawaji',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isCustomizing,
                  onChanged: (value) {
                    setState(() {
                      _isCustomizing = value;
                      if (!value) {
                        // Reset to recommended values
                        _initializeDistribution();
                      }
                    });
                  },
                ),
                Flexible(
                  child: Text(
                  _isCustomizing ? 'Mbadiliko' : 'Mpendekezo',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isCustomizing ? Colors.blue : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Show minimum reinvestment notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ProfitDistribution.minimumReinvestmentPercentage}% ya faida lazima itumike kwa mtaji wa maendeleo (Sheria ya Biashara). Unaweza kuongeza zaidi kulingana na mahitaji ya biashara.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isCustomizing) ...[
              // Show total percentage indicator with strict validation
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isValid ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.error,
                      color: isValid ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jumla: ${totalPercentage.toStringAsFixed(1)}% / 100%',
                            style: TextStyle(
                              color: isValid ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isValid) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Jumla lazima iwe haswa 100%. Sasa ni ${totalPercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Show warnings if any
              if (warnings.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: warnings.map((warning) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        warning,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
            
            _buildCustomizationItem(
              'Mtaji wa Maendeleo (Lazima)',
              'Kununua bidhaa zaidi, kuboresha huduma, kufungua tawi',
              Colors.green,
              _customReinvestment,
              _updateCustomReinvestment,
              min: ProfitDistribution.minimumReinvestmentPercentage,
              max: 60.0, // Allow up to 60% reinvestment
              isMinimum: true, // Show minimum indicator
            ),
            _buildCustomizationItem(
              'Akiba ya Biashara',
              'Emergency fund, kukabiliana na hasara',
              Colors.blue,
              _customBusinessSavings,
              _updateCustomBusinessSavings,
              min: 5.0,
              max: 50.0,
            ),
            _buildCustomizationItem(
              'Matumizi ya Biashara',
              'Kodi, mishahara, umeme, na matumizi zingine',
              Colors.orange,
              _customBusinessExpenses,
              _updateCustomBusinessExpenses,
              min: 5.0,
              max: 40.0,
            ),
            _buildCustomizationItem(
              'Matumizi Binafsi',
              'Matumizi ya mmiliki wa biashara na familia',
              Colors.purple,
              _customPersonalExpenses,
              _updateCustomPersonalExpenses,
              min: 5.0,
              max: 35.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationItem(
    String title, 
    String description, 
    Color color, 
    double value, 
    Function(double) updateValue,
    {required double min, required double max, bool isLocked = false, bool isMinimum = false}
  ) {
    // Ensure value is within valid range for the slider
    final safeValue = value.clamp(min, max);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ],
                        if (isMinimum) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_upward,
                            size: 16,
                            color: Colors.green[600],
                          ),
                        ],
                      ],
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Text(
                '${safeValue.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (_isCustomizing && !isLocked) ...[
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withOpacity(0.3),
                thumbColor: color,
                overlayColor: color.withOpacity(0.2),
              ),
              child: Slider(
                value: safeValue,
                min: min,
                max: max,
                divisions: ((max - min) * 10).round(),
                onChanged: updateValue,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${min.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${max.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          if (_isCustomizing && isLocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                    'Thibitishwa na Sheria ya Biashara',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isCustomizing && isMinimum) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                    'Thibitishwa na Sheria ya Biashara - Unaweza kuongeza zaidi',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateCustomReinvestment(double value) {
    _customReinvestment = value;
    _normalizeOtherCategories();
    _updateCustomDistribution();
  }

  void _updateCustomBusinessSavings(double value) {
    _customBusinessSavings = value;
    _normalizeOtherCategories();
    _updateCustomDistribution();
  }

  void _updateCustomBusinessExpenses(double value) {
    _customBusinessExpenses = value;
    _normalizeOtherCategories();
    _updateCustomDistribution();
  }

  void _updateCustomPersonalExpenses(double value) {
    _customPersonalExpenses = value;
    _normalizeOtherCategories();
    _updateCustomDistribution();
  }

  /// Normalize other categories to ensure total equals 100%
  void _normalizeOtherCategories() {
    // Ensure reinvestment is at least 20%
    if (_customReinvestment < ProfitDistribution.minimumReinvestmentPercentage) {
      _customReinvestment = ProfitDistribution.minimumReinvestmentPercentage;
    }

    // Calculate remaining percentage for other categories
    final remainingPercentage = 100 - _customReinvestment;
    final otherCategoriesTotal = _customBusinessSavings + _customBusinessExpenses + _customPersonalExpenses;
    
    if (otherCategoriesTotal > 0) {
      // Normalize other categories to fit within remaining percentage
      final normalizationFactor = remainingPercentage / otherCategoriesTotal;
      _customBusinessSavings = _customBusinessSavings * normalizationFactor;
      _customBusinessExpenses = _customBusinessExpenses * normalizationFactor;
      _customPersonalExpenses = _customPersonalExpenses * normalizationFactor;
    } else {
      // If all other categories are zero, distribute evenly
      final equalShare = remainingPercentage / 3;
      _customBusinessSavings = equalShare;
      _customBusinessExpenses = equalShare;
      _customPersonalExpenses = equalShare;
    }

    // Ensure values stay within slider constraints
    _customBusinessSavings = _customBusinessSavings.clamp(5.0, 50.0);
    _customBusinessExpenses = _customBusinessExpenses.clamp(5.0, 40.0);
    _customPersonalExpenses = _customPersonalExpenses.clamp(5.0, 35.0);

    // Re-normalize if clamping caused total to deviate from 100%
    final newTotal = _customReinvestment + _customBusinessSavings + _customBusinessExpenses + _customPersonalExpenses;
    if ((newTotal - 100).abs() > 0.01) {
      final remainingAfterClamp = 100 - _customReinvestment;
      final otherTotalAfterClamp = _customBusinessSavings + _customBusinessExpenses + _customPersonalExpenses;
      
      if (otherTotalAfterClamp > 0) {
        final finalNormalizationFactor = remainingAfterClamp / otherTotalAfterClamp;
        _customBusinessSavings = _customBusinessSavings * finalNormalizationFactor;
        _customBusinessExpenses = _customBusinessExpenses * finalNormalizationFactor;
        _customPersonalExpenses = _customPersonalExpenses * finalNormalizationFactor;
        
        // Clamp again to ensure we stay within bounds
        _customBusinessSavings = _customBusinessSavings.clamp(5.0, 50.0);
        _customBusinessExpenses = _customBusinessExpenses.clamp(5.0, 40.0);
        _customPersonalExpenses = _customPersonalExpenses.clamp(5.0, 35.0);
      }
    }
  }

  Widget _buildRecommendations(BusinessMetrics metrics) {
    final recommendations = _service.getDetailedRecommendations(metrics);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapendekezo na Ushauri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((recommendation) => _buildRecommendationItem(recommendation)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_distribution?.totalProfit ?? 0) <= 0 ? null : _saveDistribution,
            icon: const Icon(Icons.save),
            label: const Text('Hifadhi Ugawaji'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareDistribution,
            icon: const Icon(Icons.share),
            label: const Text('Shiriki'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _saveDistribution() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ugawaji wa faida umehifadhiwa!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareDistribution() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ugawaji wa faida umeshirikiwa!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
} 