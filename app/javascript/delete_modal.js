function confirmDelete(url) {
  document.getElementById("deleteForm").action = url;
  const modal = new bootstrap.Modal(document.getElementById("deleteModal"));
  modal.show();
}
