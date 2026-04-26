export function getQueryParam(paramName: string): string | null {
  const search = window.location.search;
  const params = new URLSearchParams(search);
  return params.get(paramName);
}
