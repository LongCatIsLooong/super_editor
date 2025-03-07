import 'package:attributed_text/attributed_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/src/core/edit_context.dart';
import 'package:super_editor/src/core/editor.dart';
import 'package:super_editor/src/default_editor/attributions.dart';
import 'package:super_editor/src/infrastructure/_logging.dart';
import 'package:super_editor/src/infrastructure/attributed_text_styles.dart';
import 'package:super_editor/src/infrastructure/keyboard.dart';

import '../core/document.dart';
import 'layout_single_column/layout_single_column.dart';
import 'paragraph.dart';
import 'text.dart';

final _log = Logger(scope: 'list_items.dart');

class ListItemNode extends TextNode {
  ListItemNode.ordered({
    required String id,
    required AttributedText text,
    Map<String, dynamic>? metadata,
    int indent = 0,
  })  : type = ListItemType.ordered,
        _indent = indent,
        super(
          id: id,
          text: text,
          metadata: metadata,
        ) {
    putMetadataValue("blockType", listItemAttribution);
  }

  ListItemNode.unordered({
    required String id,
    required AttributedText text,
    Map<String, dynamic>? metadata,
    int indent = 0,
  })  : type = ListItemType.unordered,
        _indent = indent,
        super(
          id: id,
          text: text,
          metadata: metadata,
        ) {
    putMetadataValue("blockType", listItemAttribution);
  }

  ListItemNode({
    required String id,
    required ListItemType itemType,
    required AttributedText text,
    Map<String, dynamic>? metadata,
    int indent = 0,
  })  : type = itemType,
        _indent = indent,
        super(
          id: id,
          text: text,
          metadata: metadata ?? {},
        ) {
    if (!hasMetadataValue("blockType")) {
      putMetadataValue("blockType", listItemAttribution);
    }
  }

  final ListItemType type;

  int _indent;
  int get indent => _indent;
  set indent(int newIndent) {
    if (newIndent != _indent) {
      _indent = newIndent;
      notifyListeners();
    }
  }

  @override
  bool hasEquivalentContent(DocumentNode other) {
    return other is ListItemNode && type == other.type && indent == other.indent && text == other.text;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ListItemNode &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          _indent == other._indent;

  @override
  int get hashCode => super.hashCode ^ type.hashCode ^ _indent.hashCode;
}

const listItemAttribution = NamedAttribution("listItem");

enum ListItemType {
  ordered,
  unordered,
}

class ListItemComponentBuilder implements ComponentBuilder {
  const ListItemComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! ListItemNode) {
      return null;
    }

    int? ordinalValue;
    if (node.type == ListItemType.ordered) {
      ordinalValue = 1;
      DocumentNode? nodeAbove = document.getNodeBefore(node);
      while (nodeAbove != null &&
          nodeAbove is ListItemNode &&
          nodeAbove.type == ListItemType.ordered &&
          nodeAbove.indent >= node.indent) {
        if (nodeAbove.indent == node.indent) {
          ordinalValue = ordinalValue! + 1;
        }
        nodeAbove = document.getNodeBefore(nodeAbove);
      }
    }

    return ListItemComponentViewModel(
      nodeId: node.id,
      type: node.type,
      indent: node.indent,
      ordinalValue: ordinalValue,
      text: node.text,
      textStyleBuilder: noStyleBuilder,
      selectionColor: const Color(0x00000000),
    );
  }

  @override
  Widget? createComponent(
      SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! ListItemComponentViewModel) {
      return null;
    }

    if (componentViewModel.type == ListItemType.unordered) {
      return UnorderedListItemComponent(
        componentKey: componentContext.componentKey,
        text: componentViewModel.text,
        styleBuilder: componentViewModel.textStyleBuilder,
        indent: componentViewModel.indent,
        textSelection: componentViewModel.selection,
        selectionColor: componentViewModel.selectionColor,
        highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        composingRegion: componentViewModel.composingRegion,
        showComposingUnderline: componentViewModel.showComposingUnderline,
      );
    } else if (componentViewModel.type == ListItemType.ordered) {
      return OrderedListItemComponent(
        componentKey: componentContext.componentKey,
        indent: componentViewModel.indent,
        listIndex: componentViewModel.ordinalValue!,
        text: componentViewModel.text,
        styleBuilder: componentViewModel.textStyleBuilder,
        textSelection: componentViewModel.selection,
        selectionColor: componentViewModel.selectionColor,
        highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        composingRegion: componentViewModel.composingRegion,
        showComposingUnderline: componentViewModel.showComposingUnderline,
      );
    }

    editorLayoutLog
        .warning("Tried to build a component for a list item view model without a list item type: $componentViewModel");
    return null;
  }
}

class ListItemComponentViewModel extends SingleColumnLayoutComponentViewModel with TextComponentViewModel {
  ListItemComponentViewModel({
    required String nodeId,
    double? maxWidth,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    required this.type,
    this.ordinalValue,
    required this.indent,
    required this.text,
    required this.textStyleBuilder,
    this.textDirection = TextDirection.ltr,
    this.textAlignment = TextAlign.left,
    this.selection,
    required this.selectionColor,
    this.highlightWhenEmpty = false,
    this.composingRegion,
    this.showComposingUnderline = false,
  }) : super(nodeId: nodeId, maxWidth: maxWidth, padding: padding);

  ListItemType type;
  int? ordinalValue;
  int indent;

  @override
  AttributedText text;
  @override
  AttributionStyleBuilder textStyleBuilder;
  @override
  TextDirection textDirection;
  @override
  TextAlign textAlignment;
  @override
  TextSelection? selection;
  @override
  Color selectionColor;
  @override
  bool highlightWhenEmpty;
  @override
  TextRange? composingRegion;
  @override
  bool showComposingUnderline;

  @override
  ListItemComponentViewModel copy() {
    return ListItemComponentViewModel(
      nodeId: nodeId,
      maxWidth: maxWidth,
      padding: padding,
      type: type,
      ordinalValue: ordinalValue,
      indent: indent,
      text: text,
      textStyleBuilder: textStyleBuilder,
      textDirection: textDirection,
      selection: selection,
      selectionColor: selectionColor,
      composingRegion: composingRegion,
      showComposingUnderline: showComposingUnderline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ListItemComponentViewModel &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          type == other.type &&
          ordinalValue == other.ordinalValue &&
          indent == other.indent &&
          text == other.text &&
          textDirection == other.textDirection &&
          selection == other.selection &&
          selectionColor == other.selectionColor &&
          composingRegion == other.composingRegion &&
          showComposingUnderline == other.showComposingUnderline;

  @override
  int get hashCode =>
      super.hashCode ^
      nodeId.hashCode ^
      type.hashCode ^
      ordinalValue.hashCode ^
      indent.hashCode ^
      text.hashCode ^
      textDirection.hashCode ^
      selection.hashCode ^
      selectionColor.hashCode ^
      composingRegion.hashCode ^
      showComposingUnderline.hashCode;
}

/// Displays a un-ordered list item in a document.
///
/// Supports various indentation levels, e.g., 1, 2, 3, ...
class UnorderedListItemComponent extends StatefulWidget {
  const UnorderedListItemComponent({
    Key? key,
    required this.componentKey,
    required this.text,
    required this.styleBuilder,
    this.dotBuilder = _defaultUnorderedListItemDotBuilder,
    this.indent = 0,
    this.indentCalculator = _defaultIndentCalculator,
    this.textSelection,
    this.selectionColor = Colors.lightBlueAccent,
    this.showCaret = false,
    this.caretColor = Colors.black,
    this.highlightWhenEmpty = false,
    this.composingRegion,
    this.showComposingUnderline = false,
    this.showDebugPaint = false,
  }) : super(key: key);

  final GlobalKey componentKey;
  final AttributedText text;
  final AttributionStyleBuilder styleBuilder;
  final UnorderedListItemDotBuilder dotBuilder;
  final int indent;
  final double Function(TextStyle, int indent) indentCalculator;
  final TextSelection? textSelection;
  final Color selectionColor;
  final bool showCaret;
  final Color caretColor;
  final bool highlightWhenEmpty;
  final TextRange? composingRegion;
  final bool showComposingUnderline;
  final bool showDebugPaint;

  @override
  State<UnorderedListItemComponent> createState() => _UnorderedListItemComponentState();
}

class _UnorderedListItemComponentState extends State<UnorderedListItemComponent> {
  /// A [GlobalKey] that connects a [ProxyTextDocumentComponent] to its
  /// descendant [TextComponent].
  ///
  /// The [ProxyTextDocumentComponent] doesn't know where the [TextComponent] sits
  /// in its subtree, but the proxy needs access to the [TextComponent] to provide
  /// access to text layout details.
  ///
  /// This key doesn't need to be public because the given [widget.componentKey]
  /// provides clients with direct access to text layout queries, as well as
  /// standard [DocumentComponent] queries.
  final GlobalKey _innerTextComponentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.styleBuilder({});
    final indentSpace = widget.indentCalculator(textStyle, widget.indent);
    final textScaler = MediaQuery.textScalerOf(context);
    final lineHeight = textScaler.scale(textStyle.fontSize! * (textStyle.height ?? 1.25));
    const manualVerticalAdjustment = 3.0;

    return ProxyTextDocumentComponent(
      key: widget.componentKey,
      textComponentKey: _innerTextComponentKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: indentSpace,
            margin: const EdgeInsets.only(top: manualVerticalAdjustment),
            decoration: BoxDecoration(
              border: widget.showDebugPaint ? Border.all(width: 1, color: Colors.grey) : null,
            ),
            child: SizedBox(
              height: lineHeight,
              child: widget.dotBuilder(context, widget),
            ),
          ),
          Expanded(
            child: TextComponent(
              key: _innerTextComponentKey,
              text: widget.text,
              textStyleBuilder: widget.styleBuilder,
              textSelection: widget.textSelection,
              textScaler: textScaler,
              selectionColor: widget.selectionColor,
              highlightWhenEmpty: widget.highlightWhenEmpty,
              composingRegion: widget.composingRegion,
              showComposingUnderline: widget.showComposingUnderline,
              showDebugPaint: widget.showDebugPaint,
            ),
          ),
        ],
      ),
    );
  }
}

typedef UnorderedListItemDotBuilder = Widget Function(BuildContext, UnorderedListItemComponent);

Widget _defaultUnorderedListItemDotBuilder(BuildContext context, UnorderedListItemComponent component) {
  return Align(
    alignment: Alignment.centerRight,
    child: Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: component.styleBuilder({}).color,
      ),
    ),
  );
}

/// Displays an ordered list item in a document.
///
/// Supports various indentation levels, e.g., 1, 2, 3, ...
class OrderedListItemComponent extends StatefulWidget {
  const OrderedListItemComponent({
    Key? key,
    required this.componentKey,
    required this.listIndex,
    required this.text,
    required this.styleBuilder,
    this.numeralBuilder = _defaultOrderedListItemNumeralBuilder,
    this.indent = 0,
    this.indentCalculator = _defaultIndentCalculator,
    this.textSelection,
    this.selectionColor = Colors.lightBlueAccent,
    this.showCaret = false,
    this.caretColor = Colors.black,
    this.highlightWhenEmpty = false,
    this.composingRegion,
    this.showComposingUnderline = false,
    this.showDebugPaint = false,
  }) : super(key: key);

  final GlobalKey componentKey;
  final int listIndex;
  final AttributedText text;
  final AttributionStyleBuilder styleBuilder;
  final OrderedListItemNumeralBuilder numeralBuilder;
  final int indent;
  final double Function(TextStyle, int indent) indentCalculator;
  final TextSelection? textSelection;
  final Color selectionColor;
  final bool showCaret;
  final Color caretColor;
  final bool highlightWhenEmpty;
  final TextRange? composingRegion;
  final bool showComposingUnderline;
  final bool showDebugPaint;

  @override
  State<OrderedListItemComponent> createState() => _OrderedListItemComponentState();
}

class _OrderedListItemComponentState extends State<OrderedListItemComponent> {
  /// A [GlobalKey] that connects a [ProxyTextDocumentComponent] to its
  /// descendant [TextComponent].
  ///
  /// The [ProxyTextDocumentComponent] doesn't know where the [TextComponent] sits
  /// in its subtree, but the proxy needs access to the [TextComponent] to provide
  /// access to text layout details.
  ///
  /// This key doesn't need to be public because the given [widget.componentKey]
  /// provides clients with direct access to text layout queries, as well as
  /// standard [DocumentComponent] queries.
  final GlobalKey _innerTextComponentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.styleBuilder({});
    final indentSpace = widget.indentCalculator(textStyle, widget.indent);
    final textScaler = MediaQuery.textScalerOf(context);
    final lineHeight = textScaler.scale(textStyle.fontSize! * (textStyle.height ?? 1.0));

    return ProxyTextDocumentComponent(
      key: widget.componentKey,
      textComponentKey: _innerTextComponentKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: indentSpace,
            height: lineHeight,
            decoration: BoxDecoration(
              border: widget.showDebugPaint ? Border.all(width: 1, color: Colors.grey) : null,
            ),
            child: SizedBox(
              height: lineHeight,
              child: widget.numeralBuilder(context, widget),
            ),
          ),
          Expanded(
            child: TextComponent(
              key: _innerTextComponentKey,
              text: widget.text,
              textStyleBuilder: widget.styleBuilder,
              textSelection: widget.textSelection,
              textScaler: textScaler,
              selectionColor: widget.selectionColor,
              highlightWhenEmpty: widget.highlightWhenEmpty,
              composingRegion: widget.composingRegion,
              showComposingUnderline: widget.showComposingUnderline,
              showDebugPaint: widget.showDebugPaint,
            ),
          ),
        ],
      ),
    );
  }
}

typedef OrderedListItemNumeralBuilder = Widget Function(BuildContext, OrderedListItemComponent);

double _defaultIndentCalculator(TextStyle textStyle, int indent) {
  return (textStyle.fontSize! * 0.60) * 4 * (indent + 1);
}

Widget _defaultOrderedListItemNumeralBuilder(BuildContext context, OrderedListItemComponent component) {
  return OverflowBox(
    maxWidth: double.infinity,
    maxHeight: double.infinity,
    child: Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 5.0),
        child: Text(
          '${component.listIndex}.',
          textAlign: TextAlign.right,
          style: component.styleBuilder({}).copyWith(),
        ),
      ),
    ),
  );
}

class IndentListItemRequest implements EditRequest {
  IndentListItemRequest({
    required this.nodeId,
  });

  final String nodeId;
}

class IndentListItemCommand implements EditCommand {
  IndentListItemCommand({
    required this.nodeId,
  });

  final String nodeId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.find<MutableDocument>(Editor.documentKey);
    final node = document.getNodeById(nodeId);
    final listItem = node as ListItemNode;
    if (listItem.indent >= 6) {
      _log.log('IndentListItemCommand', 'WARNING: Editor does not support an indent level beyond 6.');
      return;
    }

    listItem.indent += 1;

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(nodeId),
      )
    ]);
  }
}

class UnIndentListItemRequest implements EditRequest {
  UnIndentListItemRequest({
    required this.nodeId,
  });

  final String nodeId;
}

class UnIndentListItemCommand implements EditCommand {
  UnIndentListItemCommand({
    required this.nodeId,
  });

  final String nodeId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.find<MutableDocument>(Editor.documentKey);
    final node = document.getNodeById(nodeId);
    final listItem = node as ListItemNode;
    if (listItem.indent > 0) {
      // TODO: figure out how node changes should work in terms of
      //       a DocumentEditorTransaction (#67)
      listItem.indent -= 1;

      executor.logChanges([
        DocumentEdit(
          NodeChangeEvent(nodeId),
        )
      ]);
    } else {
      executor.executeCommand(
        ConvertListItemToParagraphCommand(
          nodeId: nodeId,
        ),
      );
    }
  }
}

class ConvertListItemToParagraphRequest implements EditRequest {
  ConvertListItemToParagraphRequest({
    required this.nodeId,
    this.paragraphMetadata,
  });

  final String nodeId;
  final Map<String, dynamic>? paragraphMetadata;
}

class ConvertListItemToParagraphCommand implements EditCommand {
  ConvertListItemToParagraphCommand({
    required this.nodeId,
    this.paragraphMetadata,
  });

  final String nodeId;
  final Map<String, dynamic>? paragraphMetadata;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.find<MutableDocument>(Editor.documentKey);
    final node = document.getNodeById(nodeId);
    final listItem = node as ListItemNode;
    final newMetadata = Map<String, dynamic>.from(paragraphMetadata ?? {});
    if (newMetadata["blockType"] == listItemAttribution) {
      newMetadata["blockType"] = paragraphAttribution;
    }

    final newParagraphNode = ParagraphNode(
      id: listItem.id,
      text: listItem.text,
      metadata: newMetadata,
    );
    document.replaceNode(oldNode: listItem, newNode: newParagraphNode);

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(listItem.id),
      )
    ]);
  }
}

class ConvertParagraphToListItemRequest implements EditRequest {
  ConvertParagraphToListItemRequest({
    required this.nodeId,
    required this.type,
  });

  final String nodeId;
  final ListItemType type;
}

class ConvertParagraphToListItemCommand implements EditCommand {
  ConvertParagraphToListItemCommand({
    required this.nodeId,
    required this.type,
  });

  final String nodeId;
  final ListItemType type;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.find<MutableDocument>(Editor.documentKey);
    final node = document.getNodeById(nodeId);
    final paragraphNode = node as ParagraphNode;

    final newListItemNode = ListItemNode(
      id: paragraphNode.id,
      itemType: type,
      text: paragraphNode.text,
    );
    document.replaceNode(oldNode: paragraphNode, newNode: newListItemNode);

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(paragraphNode.id),
      )
    ]);
  }
}

class ChangeListItemTypeRequest implements EditRequest {
  ChangeListItemTypeRequest({
    required this.nodeId,
    required this.newType,
  });

  final String nodeId;
  final ListItemType newType;
}

class ChangeListItemTypeCommand implements EditCommand {
  ChangeListItemTypeCommand({
    required this.nodeId,
    required this.newType,
  });

  final String nodeId;
  final ListItemType newType;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.find<MutableDocument>(Editor.documentKey);
    final existingListItem = document.getNodeById(nodeId) as ListItemNode;

    final newListItemNode = ListItemNode(
      id: existingListItem.id,
      itemType: newType,
      text: existingListItem.text,
    );
    document.replaceNode(oldNode: existingListItem, newNode: newListItemNode);

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(existingListItem.id),
      )
    ]);
  }
}

class SplitListItemRequest implements EditRequest {
  SplitListItemRequest({
    required this.nodeId,
    required this.splitPosition,
    required this.newNodeId,
  });

  final String nodeId;
  final TextPosition splitPosition;
  final String newNodeId;
}

class SplitListItemCommand implements EditCommand {
  SplitListItemCommand({
    required this.nodeId,
    required this.splitPosition,
    required this.newNodeId,
  });

  final String nodeId;
  final TextPosition splitPosition;
  final String newNodeId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.find<MutableDocument>(Editor.documentKey);
    final node = document.getNodeById(nodeId);
    final listItemNode = node as ListItemNode;
    final text = listItemNode.text;
    final startText = text.copyText(0, splitPosition.offset);
    final endText = splitPosition.offset < text.length ? text.copyText(splitPosition.offset) : AttributedText();
    _log.log('SplitListItemCommand', 'Splitting list item:');
    _log.log('SplitListItemCommand', ' - start text: "$startText"');
    _log.log('SplitListItemCommand', ' - end text: "$endText"');

    // Change the current node's content to just the text before the caret.
    _log.log('SplitListItemCommand', ' - changing the original list item text due to split');
    // TODO: figure out how node changes should work in terms of
    //       a DocumentEditorTransaction (#67)
    listItemNode.text = startText;

    // Create a new node that will follow the current node. Set its text
    // to the text that was removed from the current node.
    final newNode = listItemNode.type == ListItemType.ordered
        ? ListItemNode.ordered(
            id: newNodeId,
            text: endText,
            indent: listItemNode.indent,
          )
        : ListItemNode.unordered(
            id: newNodeId,
            text: endText,
            indent: listItemNode.indent,
          );

    // Insert the new node after the current node.
    _log.log('SplitListItemCommand', ' - inserting new node in document');
    document.insertNodeAfter(
      existingNode: node,
      newNode: newNode,
    );

    _log.log('SplitListItemCommand', ' - inserted new node: ${newNode.id} after old one: ${node.id}');

    executor.logChanges([
      SplitListItemIntention.start(),
      DocumentEdit(
        NodeChangeEvent(nodeId),
      ),
      DocumentEdit(
        NodeInsertedEvent(newNodeId, document.getNodeIndexById(newNodeId)),
      ),
      SplitListItemIntention.end(),
    ]);
  }
}

class SplitListItemIntention extends Intention {
  SplitListItemIntention.start() : super.start();

  SplitListItemIntention.end() : super.end();
}

ExecutionInstruction tabToIndentListItem({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.tab) {
    return ExecutionInstruction.continueExecution;
  }
  if (HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final wasIndented = editContext.commonOps.indentListItem();

  return wasIndented ? ExecutionInstruction.haltExecution : ExecutionInstruction.continueExecution;
}

ExecutionInstruction shiftTabToUnIndentListItem({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.tab) {
    return ExecutionInstruction.continueExecution;
  }
  if (!HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final wasIndented = editContext.commonOps.unindentListItem();

  return wasIndented ? ExecutionInstruction.haltExecution : ExecutionInstruction.continueExecution;
}

ExecutionInstruction backspaceToUnIndentListItem({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.backspace) {
    return ExecutionInstruction.continueExecution;
  }

  if (editContext.composer.selection == null) {
    return ExecutionInstruction.continueExecution;
  }
  if (!editContext.composer.selection!.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(editContext.composer.selection!.extent.nodeId);
  if (node is! ListItemNode) {
    return ExecutionInstruction.continueExecution;
  }
  if ((editContext.composer.selection!.extent.nodePosition as TextPosition).offset > 0) {
    return ExecutionInstruction.continueExecution;
  }

  final wasIndented = editContext.commonOps.unindentListItem();

  return wasIndented ? ExecutionInstruction.haltExecution : ExecutionInstruction.continueExecution;
}

ExecutionInstruction splitListItemWhenEnterPressed({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.enter) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(editContext.composer.selection!.extent.nodeId);
  if (node is! ListItemNode) {
    return ExecutionInstruction.continueExecution;
  }

  final didSplitListItem = editContext.commonOps.insertBlockLevelNewline();
  return didSplitListItem ? ExecutionInstruction.haltExecution : ExecutionInstruction.continueExecution;
}
