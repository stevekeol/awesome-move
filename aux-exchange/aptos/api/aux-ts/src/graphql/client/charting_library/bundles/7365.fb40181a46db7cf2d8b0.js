;(self.webpackChunktradingview = self.webpackChunktradingview || []).push([
  [7365],
  {
    42711: (t) => {
      t.exports = {
        errors: 'errors-3rBjZvef',
        show: 'show-3rBjZvef',
        error: 'error-3rBjZvef'
      }
    },
    79114: (t) => {
      t.exports = {
        'error-icon': 'error-icon-3x-w99oG',
        'intent-danger': 'intent-danger-3x-w99oG',
        'intent-warning': 'intent-warning-3x-w99oG'
      }
    },
    67276: (t) => {
      t.exports = {
        'static-messages': 'static-messages-1hgcN2c2',
        errors: 'errors-1hgcN2c2',
        warnings: 'warnings-1hgcN2c2',
        message: 'message-1hgcN2c2'
      }
    },
    18820: (t, e, r) => {
      'use strict'
      r.d(e, { getTimezoneName: () => s })
      r(84540)
      function s(t) {
        const e = t.model().timezone()
        if ('exchange' !== e) return e
        const r = t.model().mainSeries().symbolInfo()
        return null == r ? void 0 : r.timezone
      }
    },
    35347: (t, e, r) => {
      'use strict'
      r.d(e, { anchors: () => s })
      r(67294)
      const s = {
        bottom: {
          attachment: { horizontal: 'left', vertical: 'top' },
          targetAttachment: { horizontal: 'left', vertical: 'bottom' }
        },
        top: {
          attachment: { horizontal: 'left', vertical: 'bottom' },
          targetAttachment: { horizontal: 'left', vertical: 'top' }
        },
        topRight: {
          attachment: { horizontal: 'right', vertical: 'bottom' },
          targetAttachment: { horizontal: 'right', vertical: 'top' }
        },
        bottomRight: {
          attachment: { horizontal: 'right', vertical: 'top' },
          targetAttachment: { horizontal: 'right', vertical: 'bottom' }
        }
      }
    },
    11086: (t, e, r) => {
      'use strict'
      r.d(e, {
        hoverMouseEventFilter: () => n,
        useAccurateHover: () => a,
        useHover: () => o
      })
      var s = r(67294)
      function o() {
        const [t, e] = (0, s.useState)(!1)
        return [
          t,
          {
            onMouseOver: function (t) {
              n(t) && e(!0)
            },
            onMouseOut: function (t) {
              n(t) && e(!1)
            }
          }
        ]
      }
      function n(t) {
        return !t.currentTarget.contains(t.relatedTarget)
      }
      function a(t) {
        const [e, r] = (0, s.useState)(!1)
        return (
          (0, s.useEffect)(() => {
            const e = (e) => {
              if (null === t.current) return
              const s = t.current.contains(e.target)
              r(s)
            }
            return (
              document.addEventListener('mouseover', e),
              () => document.removeEventListener('mouseover', e)
            )
          }, []),
          e
        )
      }
    },
    91943: (t, e, r) => {
      'use strict'
      r.d(e, { FormInput: () => c })
      var s = r(67294),
        o = r(81829),
        n = r(16305),
        a = r(92136),
        i = r(66213),
        h = r(66364)
      function c(t) {
        var e
        const {
            intent: r,
            onFocus: c,
            onBlur: l,
            onMouseOver: m,
            onMouseOut: d,
            containerReference: g = null,
            endSlot: p,
            hasErrors: u,
            hasWarnings: f,
            errors: w,
            warnings: v,
            alwaysShowAttachedErrors: E,
            iconHidden: b,
            messagesPosition: A,
            messagesAttachment: M,
            customErrorsAttachment: S,
            messagesRoot: R,
            inheritMessagesWidthFromTarget: _,
            disableMessagesRtlStyles: W,
            ...x
          } = t,
          y = (0, n.useControlValidationLayout)({
            hasErrors: u,
            hasWarnings: f,
            errors: w,
            warnings: v,
            alwaysShowAttachedErrors: E,
            iconHidden: b,
            messagesPosition: A,
            messagesAttachment: M,
            customErrorsAttachment: S,
            messagesRoot: R,
            inheritMessagesWidthFromTarget: _,
            disableMessagesRtlStyles: W
          }),
          z = (0, i.createSafeMulticastEventHandler)(c, y.onFocus),
          C = (0, i.createSafeMulticastEventHandler)(l, y.onBlur),
          O = (0, i.createSafeMulticastEventHandler)(m, y.onMouseOver),
          T = (0, i.createSafeMulticastEventHandler)(d, y.onMouseOut)
        return s.createElement(
          s.Fragment,
          null,
          s.createElement(o.InputControl, {
            ...x,
            intent: null !== (e = y.intent) && void 0 !== e ? e : r,
            onFocus: z,
            onBlur: C,
            onMouseOver: O,
            onMouseOut: T,
            containerReference: (0, h.useMergedRefs)([g, y.containerReference]),
            endSlot: s.createElement(
              s.Fragment,
              null,
              y.icon && s.createElement(a.EndSlot, { icon: !0 }, y.icon),
              p
            )
          }),
          y.renderedErrors
        )
      }
    },
    16305: (t, e, r) => {
      'use strict'
      r.d(e, { MessagesPosition: () => A, useControlValidationLayout: () => C })
      var s = r(67294),
        o = r(94184),
        n = r(15965),
        a = r(11086),
        i = r(92136),
        h = r(35347),
        c = r(36668),
        l = r(73935)
      var m = r(42711),
        d = r(76553)
      class g extends s.PureComponent {
        render() {
          const {
              children: t = [],
              show: e = !1,
              customErrorClass: r,
              disableRtlStyles: n
            } = this.props,
            a = o(m.errors, { [m.show]: e }, r),
            i = t.map((t, e) =>
              s.createElement('div', { className: m.error, key: e }, t)
            )
          let h = {
            position: 'absolute',
            top: this.props.top,
            width: this.props.width,
            height: this.props.height,
            bottom: void 0 !== this.props.bottom ? this.props.bottom : '100%',
            right: void 0 !== this.props.right ? this.props.right : 0,
            left: this.props.left,
            zIndex: this.props.zIndex,
            maxWidth: this.props.maxWidth
          }
          if ((0, d.isRtl)() && !n) {
            const { left: t, right: e } = h
            h = { ...h, left: e, right: t }
          }
          return s.createElement('div', { style: h, className: a }, i)
        }
      }
      const p = (0, c.makeOverlapable)(
        ((u = g),
        ((f = class extends s.PureComponent {
          constructor(t) {
            super(t),
              (this._getComponentInstance = (t) => {
                this._instance = t
              }),
              (this._throttleCalcProps = () => {
                requestAnimationFrame(() =>
                  this.setState(this._calcProps(this.props))
                )
              }),
              (this.state = this._getStateFromProps())
          }
          componentDidMount() {
            ;(this._instanceElem = l.findDOMNode(this._instance)),
              this.props.attachOnce || this._subscribe(),
              this.setState(this._calcProps(this.props))
          }
          componentDidUpdate(t) {
            ;(t.children === this.props.children &&
              t.top === this.props.top &&
              t.left === this.props.left &&
              t.width === this.props.width) ||
              this.setState(this._getStateFromProps(), () =>
                this.setState(this._calcProps(this.props))
              )
          }
          render() {
            return s.createElement(
              'div',
              {
                style: { position: 'absolute', width: '100%', top: 0, left: 0 }
              },
              s.createElement(
                u,
                {
                  ...this.props,
                  ref: this._getComponentInstance,
                  top: this.state.top,
                  bottom:
                    void 0 !== this.state.bottom ? this.state.bottom : 'auto',
                  right:
                    void 0 !== this.state.right ? this.state.right : 'auto',
                  left: this.state.left,
                  width: this.state.width,
                  maxWidth: this.state.maxWidth
                },
                this.props.children
              )
            )
          }
          componentWillUnmount() {
            this._unsubsribe()
          }
          _getStateFromProps() {
            return {
              bottom: this.props.bottom,
              left: this.props.left,
              right: this.props.right,
              top: void 0 !== this.props.top ? this.props.top : -1e4,
              width: this.props.inheritWidthFromTarget
                ? this.props.target &&
                  this.props.target.getBoundingClientRect().width
                : this.props.width,
              maxWidth:
                this.props.inheritMaxWidthFromTarget &&
                this.props.target &&
                this.props.target.getBoundingClientRect().width
            }
          }
          _calcProps(t) {
            if (t.target && t.attachment && t.targetAttachment) {
              const e = this._calcTargetProps(
                t.target,
                t.attachment,
                t.targetAttachment
              )
              if (null === e) return {}
              const {
                  width: r,
                  inheritWidthFromTarget: s = !0,
                  inheritMaxWidthFromTarget: o = !1
                } = this.props,
                n = { width: s ? e.width : r, maxWidth: o ? e.width : void 0 }
              switch (t.attachment.vertical) {
                case 'bottom':
                case 'middle':
                  n.top = e.y
                  break
                default:
                  n[t.attachment.vertical] = e.y
              }
              switch (t.attachment.horizontal) {
                case 'right':
                case 'center':
                  n.left = e.x
                  break
                default:
                  n[t.attachment.horizontal] = e.x
              }
              return n
            }
            return {}
          }
          _calcTargetProps(t, e, r) {
            const s = t.getBoundingClientRect(),
              o = this._instanceElem.getBoundingClientRect(),
              n =
                'parent' === this.props.root
                  ? this._getCoordsRelToParentEl(t, s)
                  : this._getCoordsRelToDocument(s)
            if (null === n) return null
            const a = this._getDimensions(o),
              i = this._getDimensions(s).width
            let h = 0,
              c = 0
            switch (e.vertical) {
              case 'top':
                c = n[r.vertical]
                break
              case 'bottom':
                c = n[r.vertical] - a.height
                break
              case 'middle':
                c = n[r.vertical] - a.height / 2
            }
            switch (e.horizontal) {
              case 'left':
                h = n[r.horizontal]
                break
              case 'right':
                h = n[r.horizontal] - a.width
                break
              case 'center':
                h = n[r.horizontal] - a.width / 2
            }
            return (
              'number' == typeof this.props.attachmentOffsetY &&
                (c += this.props.attachmentOffsetY),
              'number' == typeof this.props.attachmentOffsetX &&
                (h += this.props.attachmentOffsetX),
              { x: h, y: c, width: i }
            )
          }
          _getCoordsRelToDocument(t) {
            const e = pageYOffset,
              r = pageXOffset,
              s = t.top + e,
              o = t.bottom + e,
              n = t.left + r
            return {
              top: s,
              bottom: o,
              left: n,
              right: t.right + r,
              middle: (s + t.height) / 2,
              center: n + t.width / 2
            }
          }
          _getCoordsRelToParentEl(t, e) {
            const r = t.offsetParent
            if (null === r) return null
            const s = r.scrollTop,
              o = r.scrollLeft,
              n = t.offsetTop + s,
              a = t.offsetLeft + o,
              i = e.width + a
            return {
              top: n,
              bottom: e.height + n,
              left: a,
              right: i,
              middle: (n + e.height) / 2,
              center: (a + e.width) / 2
            }
          }
          _getDimensions(t) {
            return { height: t.height, width: t.width }
          }
          _subscribe() {
            'document' === this.props.root &&
              (window.addEventListener('scroll', this._throttleCalcProps, !0),
              window.addEventListener('resize', this._throttleCalcProps))
          }
          _unsubsribe() {
            window.removeEventListener('scroll', this._throttleCalcProps, !0),
              window.removeEventListener('resize', this._throttleCalcProps)
          }
        }).displayName = 'Attachable Component'),
        f)
      )
      var u,
        f,
        w = r(49775),
        v = r(26176),
        E = r(79114)
      function b(t) {
        const { intent: e = 'danger' } = t
        return s.createElement(w.Icon, {
          icon: v,
          className: o(E['error-icon'], E['intent-' + e])
        })
      }
      var A,
        M,
        S = r(67276)
      !(function (t) {
        ;(t[(t.Attached = 0)] = 'Attached'),
          (t[(t.Static = 1)] = 'Static'),
          (t[(t.Hidden = 2)] = 'Hidden')
      })(A || (A = {})),
        (function (t) {
          ;(t.Top = 'top'), (t.Bottom = 'bottom')
        })(M || (M = {}))
      const R = {
        top: {
          attachment: h.anchors.topRight.attachment,
          targetAttachment: h.anchors.topRight.targetAttachment,
          attachmentOffsetY: -4
        },
        bottom: {
          attachment: h.anchors.bottomRight.attachment,
          targetAttachment: h.anchors.bottomRight.targetAttachment,
          attachmentOffsetY: 4
        }
      }
      function _(t) {
        const {
            isOpened: e,
            target: r,
            errorAttachment: o = M.Top,
            customErrorsAttachment: n,
            root: a = 'parent',
            inheritWidthFromTarget: i = !1,
            disableRtlStyles: h,
            children: c
          } = t,
          {
            attachment: l,
            targetAttachment: m,
            attachmentOffsetY: d
          } = null != n ? n : R[o]
        return s.createElement(
          p,
          {
            isOpened: e,
            target: r,
            root: a,
            inheritWidthFromTarget: i,
            attachment: l,
            targetAttachment: m,
            attachmentOffsetY: d,
            disableRtlStyles: h,
            inheritMaxWidthFromTarget: !0,
            show: !0
          },
          c
        )
      }
      function W(t, e) {
        return Boolean(t) && void 0 !== e && e.length > 0
      }
      function x(t, e, r) {
        return t === A.Attached && W(e, r)
      }
      function y(t, e, r) {
        return t === A.Static && W(e, r)
      }
      function z(t, e, r) {
        const {
            hasErrors: s,
            hasWarnings: o,
            alwaysShowAttachedErrors: n,
            iconHidden: a,
            errors: i,
            warnings: h,
            messagesPosition: c = A.Static
          } = t,
          l = x(c, s, i),
          m = x(c, o, h),
          d = l && (e || r || Boolean(n)),
          g = !d && m && (e || r),
          p = y(c, s, i),
          u = !p && y(c, o, h),
          f = !a && Boolean(s)
        return {
          hasAttachedErrorMessages: l,
          hasAttachedWarningMessages: m,
          showAttachedErrorMessages: d,
          showAttachedWarningMessages: g,
          showStaticErrorMessages: p,
          showStaticWarningMessages: u,
          showErrorIcon: f,
          showWarningIcon: !a && !f && Boolean(o),
          intent: (function (t, e) {
            return Boolean(t) ? 'danger' : Boolean(e) ? 'warning' : void 0
          })(s, o)
        }
      }
      function C(t) {
        var e, r
        const {
            errors: h,
            warnings: c,
            messagesAttachment: l,
            customErrorsAttachment: m,
            messagesRoot: d,
            inheritMessagesWidthFromTarget: g,
            disableMessagesRtlStyles: p
          } = t,
          [u, f] = (0, n.useFocus)(),
          [w, v] = (0, a.useHover)(),
          E = (0, s.useRef)(null),
          {
            hasAttachedErrorMessages: A,
            hasAttachedWarningMessages: M,
            showAttachedErrorMessages: R,
            showAttachedWarningMessages: W,
            showStaticErrorMessages: x,
            showStaticWarningMessages: y,
            showErrorIcon: C,
            showWarningIcon: O,
            intent: T
          } = z(t, u, w),
          F =
            C || O
              ? s.createElement(b, { intent: C ? 'danger' : 'warning' })
              : void 0,
          P = A
            ? s.createElement(_, {
                errorAttachment: l,
                customErrorsAttachment: m,
                isOpened: R,
                target: E.current,
                root: d,
                inheritWidthFromTarget: g,
                disableRtlStyles: p,
                children: h
              })
            : void 0,
          B = M
            ? s.createElement(_, {
                errorAttachment: l,
                isOpened: W,
                target: E.current,
                root: d,
                inheritWidthFromTarget: g,
                disableRtlStyles: p,
                children: c
              })
            : void 0,
          k = x
            ? s.createElement(
                i.AfterSlot,
                { className: o(S['static-messages'], S.errors) },
                null == h
                  ? void 0
                  : h.map((t, e) =>
                      s.createElement('p', { key: e, className: S.message }, t)
                    )
              )
            : void 0,
          N = y
            ? s.createElement(
                i.AfterSlot,
                { className: o(S['static-messages'], S.warnings) },
                null == c
                  ? void 0
                  : c.map((t, e) =>
                      s.createElement('p', { key: e, className: S.message }, t)
                    )
              )
            : void 0
        return {
          icon: F,
          renderedErrors:
            null !==
              (r = null !== (e = null != P ? P : B) && void 0 !== e ? e : k) &&
            void 0 !== r
              ? r
              : N,
          containerReference: E,
          intent: T,
          ...f,
          ...v
        }
      }
    },
    26176: (t) => {
      t.exports =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" fill="none"><path fill="currentColor" fill-rule="evenodd" clip-rule="evenodd" d="M8 15c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm0 1c4.418 0 8-3.582 8-8s-3.582-8-8-8-8 3.582-8 8 3.582 8 8 8zm-1-12c0-.552.448-1 1-1s1 .448 1 1v4c0 .552-.448 1-1 1s-1-.448-1-1v-4zm1 7c-.552 0-1 .448-1 1s.448 1 1 1 1-.448 1-1-.448-1-1-1z"/></svg>'
    }
  }
])
