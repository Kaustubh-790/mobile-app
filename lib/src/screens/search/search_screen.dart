import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/service_model.dart';
import '../../widgets/service_card.dart';
import '../service/service_detail_screen.dart';
import '../../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ServiceModel> _allServices = [];
  List<ServiceModel> _filteredServices = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAllServices();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterServices(_searchController.text);
  }

  Future<void> _loadAllServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final services = await ApiService.getAllServices();
      setState(() {
        _allServices = services;
        _filteredServices = _allServices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading services: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  void _filterServices(String query) {
    setState(() {
      _hasSearched = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredServices = _allServices;
        _hasSearched = false;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredServices = _allServices.where((service) {
          return service.title.toLowerCase().contains(lowerQuery) ||
              service.description.toLowerCase().contains(lowerQuery) ||
              service.code.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        backgroundColor: AppTheme.beigeDefault,
        title: Text(
          'SEARCH SERVICES',
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.brown500),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  return TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.brown500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search for services...',
                      hintStyle: TextStyle(color: AppTheme.brown300),
                      prefixIcon: Icon(Icons.search, color: AppTheme.brown400),
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppTheme.brown400),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppTheme.beige10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppTheme.beige10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppTheme.primaryDefault),
                      ),
                      filled: true,
                      fillColor: AppTheme.sand50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    textInputAction: TextInputAction.search,
                  );
                },
              ),
            ),
            
            // Results count or All services label
            if (!_isLoading && _filteredServices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _hasSearched
                        ? 'Found ${_filteredServices.length} service${_filteredServices.length == 1 ? '' : 's'}'
                        : 'All Services (${_filteredServices.length})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.brown300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // Content
            Expanded(
              child: _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDefault),
            ),
            SizedBox(height: 16),
            Text('Loading services...', style: TextStyle(color: AppTheme.brown300)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading services',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.brown300,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAllServices,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDefault,
                foregroundColor: AppTheme.beige4,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_hasSearched && _filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.brown200,
            ),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.brown300,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredServices.isEmpty && _allServices.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppTheme.brown200,
            ),
            const SizedBox(height: 16),
            Text(
              'No services available',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no services available at the moment',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.brown300,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredServices.length,
      itemBuilder: (context, index) {
        final service = _filteredServices[index];
        return ServiceCard(
          service: service,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailScreen(
                  serviceSlug: service.slug,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
