const staticAssets = (request, env) => env.ASSETS.fetch(request);

export default {
  async fetch(request, env) {
    const response = await staticAssets(request, env);
    if (response.status !== 404 || request.method !== 'GET') return response;

    const url = new URL(request.url);
    const finalSegment = url.pathname.split('/').pop() ?? '';
    if (finalSegment.includes('.')) return response;

    url.pathname = '/index.html';
    return staticAssets(new Request(url, request), env);
  },
};
