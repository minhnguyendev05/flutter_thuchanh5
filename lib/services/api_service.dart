class ApiService {
  Future<List<Map<String, dynamic>>> fetchSampleTips() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return [
      {
        'title': '50/30/20 Rule',
        'description': 'Giữ chi tiêu linh hoạt trong 50%, nhu cầu cá nhân 30%, tiết kiệm 20%.',
      },
      {
        'title': 'Track Daily',
        'description': 'Cập nhật giao dịch mỗi ngày giúp dữ liệu chính xác hơn cuối tháng.',
      },
    ];
  }
}
