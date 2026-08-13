/// 后端 Cloudflare Worker 的基础地址——AI 深度解读和实体牌拍照识别
/// 共用同一个 Worker（不同路径），改地址只需要改这一处。
class WorkerConfig {
  const WorkerConfig._();

  static const baseUrl = 'https://tarot-ai-reading.jchatarot22.workers.dev';
}
