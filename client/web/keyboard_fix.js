window.ios_keyboard_hack = {
  _isFighting: false,
  _input: null,

  prime: function () {
    this._input = document.getElementById('ios-keyboard-primer');
    if (!this._input) return;

    this._isFighting = true;
    this._doFocus();

    const self = this;
    const fight = () => {
      if (!self._isFighting) return;

      const active = document.activeElement;
      if (active !== self._input && active.tagName !== 'INPUT' && active.tagName !== 'TEXTAREA') {
        self._doFocus();
      }
      requestAnimationFrame(fight);
    };
    requestAnimationFrame(fight);

    // Safety timeout to prevent infinite loops if something goes wrong
    setTimeout(() => { if (this._isFighting) this._isFighting = false; }, 3000);
  },

  _doFocus: function () {
    if (!this._input) return;
    this._input.focus();
    this._input.click();
    this._input.setSelectionRange(0, 0);
  },

  stop: function () {
    this._isFighting = false;
  }
};
